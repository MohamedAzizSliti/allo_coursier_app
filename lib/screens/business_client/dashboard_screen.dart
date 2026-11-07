import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/tarif_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_api_service.dart';
import '../../services/commande_api_service.dart';
import '../../services/session_controller.dart';
import '../../services/tarif_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import 'widget/WeeklyPlanWidget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onSeeAll});

  final VoidCallback? onSeeAll;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CommandeApiService _commandeService = CommandeApiService();
  final TarifApiService _tarifService = TarifApiService();

  List<TarifModel> _tarifs = [];
  Map<String, int> _counts = const {};
  int _total = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<String?> _resolveUserId() async {
    final sessionId = SessionController.instance.user?.id;
    if (sessionId != null && sessionId.isNotEmpty) return sessionId;
    final stored = await AlloApi.instance.getStoredUserId();
    if (stored != null && stored.isNotEmpty) return stored;
    try {
      final me = await AuthApiService().getCurrentUser();
      SessionController.instance.rememberUser(me);
      if (me.id.isNotEmpty) return me.id;
    } catch (_) {}
    return null;
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final userId = await _resolveUserId();
    if (!mounted) return;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = context.s.cannotLoadDashboard;
      });
      return;
    }

    String? colisError;
    try {
      final counts = await _commandeService.shipmentTotalsForUser(userId);
      if (!mounted) return;
      _counts = counts;
      _total = counts['Tous'] ?? 0;
    } on AlloException catch (e) {
      if (e.isUnauthorized) {
        await SessionController.instance.signedOut();
        return;
      }
      colisError = e.message;
    } catch (_) {
      colisError = context.s.cannotLoadDashboard;
    }

    try {
      _tarifs = await _tarifService.listTarifs();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = colisError;
    });
  }

  int _countStatus(String status) => _counts[status] ?? 0;

  int get _livre => _countStatus('Livré');

  int get _paye => _countStatus('Payé');

  int get _circulation =>
      _countStatus('En cours') +
      _countStatus('En dépôt') +
      _countStatus('En route');

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final total = _total;
    final dateLabel = MaterialLocalizations.of(context).formatFullDate(
      DateTime.now(),
    );

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.brand,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            if (_error != null) ErrorBanner(message: _error!, onRetry: _fetchData),
            ListenableBuilder(
              listenable: SessionController.instance,
              builder: (context, _) {
                final raw = SessionController.instance.user?.name.trim();
                final name =
                    (raw != null && raw.isNotEmpty) ? raw : s.roleSender;
                return SenderHeroCard(
                  dateLabel: dateLabel,
                  greeting: s.helloName(name),
                  total: total,
                  circulation: _circulation,
                  deliveredPct: s.percentOf(_pct(_livre + _paye, total)),
                  paidPct: s.percentOf(_pct(_paye, total)),
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: WebSurfaces.card(radius: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.distribution,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.espresso,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onSeeAll,
                        child: Text(s.seeAll),
                      ),
                    ],
                  ),
                  _StatusRow(
                    label: s.inProgress,
                    color: AppColors.warning,
                    count: _countStatus('En cours'),
                    total: total,
                  ),
                  _StatusRow(
                    label: s.inDepot,
                    color: AppColors.depot,
                    count: _countStatus('En dépôt'),
                    total: total,
                  ),
                  _StatusRow(
                    label: s.inRoute,
                    color: AppColors.info,
                    count: _countStatus('En route'),
                    total: total,
                  ),
                  _StatusRow(
                    label: s.redeliver,
                    color: AppColors.relivrer,
                    count: _countStatus('Relivrer'),
                    total: total,
                  ),
                  _StatusRow(
                    label: s.delivered,
                    color: AppColors.success,
                    count: _livre,
                    total: total,
                  ),
                  _StatusRow(
                    label: s.paid,
                    color: AppColors.mocha,
                    count: _paye,
                    total: total,
                  ),
                  _StatusRow(
                    label: s.cancelled,
                    color: AppColors.error,
                    count: _countStatus('Annuler'),
                    total: total,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: WebSurfaces.card(radius: 24),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.newRules,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RuleItem(text: s.rulePacked),
                    RuleItem(text: s.rulePayConfirm),
                    RuleItem(text: s.ruleReturnFees),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            WeeklyPlanWidget(),
            const SizedBox(height: 16),
            Text(
              s.tarifs,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 10),
            ..._tarifs.map(
              (tarif) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: WebSurfaces.card(radius: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.cream,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: AppColors.brand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tarif.type,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                              ),
                            ),
                            Text(
                              s.priceReturn('${tarif.prix} DT', '${tarif.prixRetour} DT'),
                              style: const TextStyle(color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _pct(int part, int total) {
    if (total <= 0) return 0;
    return (part / total) * 100;
  }
}

class SenderHeroCard extends StatelessWidget {
  const SenderHeroCard({
    super.key,
    required this.dateLabel,
    required this.greeting,
    required this.total,
    required this.circulation,
    required this.deliveredPct,
    required this.paidPct,
  });

  final String dateLabel;
  final String greeting;
  final int total;
  final int circulation;
  final String deliveredPct;
  final String paidPct;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            greeting,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            s.parcelsTotal,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric(s.inCirculation, '$circulation'),
              _metric(s.deliveredShare, deliveredPct),
              _metric(s.paidShare, paidPct),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.color,
    required this.count,
    required this.total,
  });

  final String label;
  final Color color;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0.0 : (count / total) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.espresso,
              ),
            ),
          ),
          Text(
            context.s.percentOf(pct),
            style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.espresso,
            ),
          ),
        ],
      ),
    );
  }
}

class RuleItem extends StatelessWidget {
  const RuleItem({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
