import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../models/parcel_status.dart';
import '../../services/api_client.dart';
import '../../services/commande_api_service.dart';
import '../../services/parcel_transition_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/scan_manual_entry.dart';
import '../agent/ColisDetailsScreen.dart';
import '../agent/commande_details_screen.dart';
import 'scan_confirm_dialog.dart';
import 'scan_outcome_sheet.dart';

class ParcelScannerScreen extends StatefulWidget {
  const ParcelScannerScreen({super.key, required this.role});

  final String role;

  @override
  State<ParcelScannerScreen> createState() => _ParcelScannerScreenState();
}

class _ParcelScannerScreenState extends State<ParcelScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'parcelQR');
  final CommandeApiService _commandeService = CommandeApiService();
  final ParcelTransitionService _transitions = const ParcelTransitionService();

  QRViewController? _controller;
  bool _busy = false;
  String? _lastCode;

  @override
  void initState() {
    super.initState();
    unawaited(Permission.camera.request());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scanData) {
      unawaited(_lookupCode(scanData.code));
    });
  }

  Future<void> _lookupCode(String? raw) async {
    final code = raw?.trim() ?? '';
    if (_busy || code.isEmpty) return;
    setState(() {
      _busy = true;
      _lastCode = code;
    });
    await _controller?.pauseCamera();
    await _handleScan(code);
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 400));
    await _controller?.resumeCamera();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _handleScan(String raw) async {
    try {
      final commande = await _commandeService.scannerLookup(raw);
      if (!mounted) return;
      final status = parseParcelStatus(commande.status);
      if (status == null) {
        _toast('${context.s.unknownStatus} : ${commande.status}');
        return;
      }
      final intent = _transitions.scanIntent(
        status,
        parseOfficeRole(widget.role),
      );
      await _showConfirm(commande, intent);
    } on AlloException catch (e) {
      if (!mounted) return;
      await _showScanError(
        _transitions.scanLookupError(
          parseOfficeRole(widget.role),
          e,
          context.s,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final driver = parseOfficeRole(widget.role) == OfficeRole.deliveryPerson;
      await _showScanError(
        driver ? context.s.scanNotAssigned : context.s.parcelNotFound,
      );
    }
  }

  Future<void> _showScanError(String message) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: AppColors.brand, size: 36),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.espresso,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(context.s.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConfirm(CommandeModel commande, ScanIntent intent) async {
    if (intent == ScanIntent.detailsOnly) {
      _toast(context.s.parcelStatusLine(commande.displayId, commande.status));
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommandeDetailsScreen(commandeId: commande.id),
        ),
      );
      return;
    }

    if (intent == ScanIntent.confirmColis) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => ScanConfirmDialog(
          displayId: commande.displayId,
          status: commande.status,
          message: context.s.confirmReceiveDepot,
          confirmLabel: context.s.continueAction,
        ),
      );
      if (go == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ColisDetailsScreen(colisId: commande.id),
          ),
        );
      }
      return;
    }

    if (intent == ScanIntent.claim) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => ScanConfirmDialog(
          displayId: commande.displayId,
          status: commande.status,
          message: context.s.loadInRoute,
        ),
      );
      if (go == true && mounted) {
        await _run(
          () => _commandeService.claim(commande.id),
          context.s.parcelInRoute,
        );
      }
      return;
    }

    await _showOutcomeDialog(commande);
  }

  Future<void> _showOutcomeDialog(CommandeModel commande) async {
    final outcome = await ScanOutcomeSheet.show(
      context,
      displayId: commande.displayId,
      status: commande.status,
    );
    if (outcome == null || !mounted) return;
    switch (outcome.action) {
      case 'Livrer':
        await _run(
          () => _commandeService.deliver(commande.id),
          context.s.parcelDelivered,
        );
      case 'Relivrer':
        await _run(
          () => _commandeService.relivrer(commande.id, reason: outcome.reason),
          context.s.parcelToRedeliver,
        );
      case 'Annuler':
        await _run(
          () => _commandeService.annuler(commande.id, reason: outcome.reason),
          context.s.parcelCancelled,
        );
    }
  }

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    try {
      await action();
      if (!mounted) return;
      _toast(okMessage);
    } on AlloException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (_) {
      if (!mounted) return;
      _toast(context.s.updateError);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: Text(context.s.scanQr)),
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.espresso,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.cream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        color: AppColors.brand,
                        backgroundColor: AppColors.field,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _lastCode == null
                            ? context.s.scanHint
                            : context.s.codeLabel(_lastCode!),
                        style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ScanManualEntry(
                    enabled: !_busy,
                    onSubmit: (code) => unawaited(_lookupCode(code)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
