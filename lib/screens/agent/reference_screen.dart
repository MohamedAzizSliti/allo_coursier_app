import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/places_api_service.dart';
import '../../services/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../business_client/add_order_screen.dart' show kTunisianGovernorates;

class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.referenceData),
        bottom: TabBar(
          controller: _tabs,
          // AppBar is brand brown — primary selected color would match the bg.
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.tan,
          indicatorWeight: 3,
          tabs: [
            Tab(text: s.gouvernoratsTab),
            Tab(text: s.villesTab),
            Tab(text: s.secteursTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _GouvernoratsPanel(),
          _VillesPanel(),
          _SecteursPanel(),
        ],
      ),
    );
  }
}

class _GouvernoratsPanel extends StatefulWidget {
  const _GouvernoratsPanel();

  @override
  State<_GouvernoratsPanel> createState() => _GouvernoratsPanelState();
}

class _GouvernoratsPanelState extends State<_GouvernoratsPanel> {
  final PlacesApiService _api = PlacesApiService();
  List<GouvernoratPlace> _rows = [];
  bool _loading = true;
  String? _error;
  bool _showArchived = false;

  bool get _isAdmin => SessionController.instance.role == 'admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _api.listGouvernorats();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.s.cannotLoadReference;
      });
    }
  }

  Set<String> get _duplicates {
    final counts = <String, int>{};
    for (final row in _rows) {
      if (!row.active || row.gouvernorat == null) continue;
      counts[row.gouvernorat!] = (counts[row.gouvernorat!] ?? 0) + 1;
    }
    return counts.entries.where((e) => e.value > 1).map((e) => e.key).toSet();
  }

  Future<void> _rename(GouvernoratPlace row) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _RenameGouvernoratDialog(initial: row.gouvernorat),
    );
    if (value == null || value.isEmpty) return;
    try {
      await _api.renameGouvernorat(row.id, value);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.referenceSaved)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.errorLine('$e'))));
    }
  }

  Future<void> _merge(GouvernoratPlace row) async {
    final targets = _rows.where((r) => r.active && r.id != row.id).toList();
    if (targets.isEmpty) return;
    final intoId = await showDialog<String>(
      context: context,
      builder: (context) => _MergeDialog(row: row, targets: targets),
    );
    if (intoId == null || intoId.isEmpty) return;
    try {
      await _api.mergeGouvernorats(row.id, intoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.referenceSaved)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.errorLine('$e'))));
    }
  }

  Future<void> _toggle(GouvernoratPlace row) async {
    try {
      await _api.setGouvernoratActive(row.id, !row.active);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.errorLine('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading && _rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _rows.isEmpty) {
      return ErrorBanner(message: _error!, onRetry: _load);
    }
    final visible =
        _showArchived ? _rows : _rows.where((r) => r.active).toList();
    final duplicates = _duplicates;
    final activeCount = _rows.where((r) => r.active).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.showArchived),
            value: _showArchived,
            onChanged: (v) => setState(() => _showArchived = v),
          ),
          if (visible.isEmpty)
            EmptyState(message: s.noGouvernorats, icon: Icons.map_outlined)
          else
            ...visible.map((row) {
              final usage = row.tickets == null || row.villes == null
                  ? s.usageUnknown
                  : s.usageCounts(row.tickets!, row.villes!);
              return Card(
                child: ListTile(
                  title: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(row.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (row.gouvernorat == null)
                        Chip(
                          label: Text(s.unrecognized, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.red.shade50,
                        ),
                      if (row.active &&
                          row.gouvernorat != null &&
                          duplicates.contains(row.gouvernorat))
                        Chip(
                          label: Text(s.duplicate, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (!row.active)
                        Chip(
                          label: Text(s.archived, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  subtitle: Text('${row.tarif.toStringAsFixed(0)} DT · $usage'),
                  trailing: _isAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: s.renameGouvernorat,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _rename(row),
                            ),
                            if (row.active && activeCount > 1)
                              IconButton(
                                tooltip: s.mergeGouvernorat,
                                icon: const Icon(Icons.merge_type),
                                onPressed: () => _merge(row),
                              ),
                            IconButton(
                              tooltip: row.active ? s.archive : s.restore,
                              icon: Icon(
                                row.active
                                    ? Icons.archive_outlined
                                    : Icons.unarchive_outlined,
                              ),
                              onPressed: () => _toggle(row),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RenameGouvernoratDialog extends StatefulWidget {
  const _RenameGouvernoratDialog({this.initial});

  final String? initial;

  @override
  State<_RenameGouvernoratDialog> createState() =>
      _RenameGouvernoratDialogState();
}

class _RenameGouvernoratDialogState extends State<_RenameGouvernoratDialog> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.renameGouvernorat),
      content: DropdownButtonFormField<String>(
        initialValue: _value,
        items: kTunisianGovernorates
            .map(
              (g) => DropdownMenuItem(
                value: g.apiValue,
                child: Text(g.label(s.ar)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _value = v),
        decoration: InputDecoration(labelText: s.governorate),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        FilledButton(
          onPressed: _value == null || _value!.isEmpty
              ? null
              : () => Navigator.pop(context, _value),
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _MergeDialog extends StatefulWidget {
  const _MergeDialog({required this.row, required this.targets});

  final GouvernoratPlace row;
  final List<GouvernoratPlace> targets;

  @override
  State<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends State<_MergeDialog> {
  late String? _intoId = () {
    for (final t in widget.targets) {
      if (t.gouvernorat == widget.row.gouvernorat) return t.id;
    }
    return widget.targets.isEmpty ? null : widget.targets.first.id;
  }();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text('${s.mergeGouvernorat} « ${widget.row.label} »'),
      content: DropdownButtonFormField<String>(
        initialValue: _intoId,
        items: widget.targets
            .map(
              (t) => DropdownMenuItem(value: t.id, child: Text(t.label)),
            )
            .toList(),
        onChanged: (v) => setState(() => _intoId = v),
        decoration: InputDecoration(labelText: s.mergeInto),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        FilledButton(
          onPressed: _intoId == null
              ? null
              : () => Navigator.pop(context, _intoId),
          child: Text(s.mergeGouvernorat),
        ),
      ],
    );
  }
}

class _VillesPanel extends StatefulWidget {
  const _VillesPanel();

  @override
  State<_VillesPanel> createState() => _VillesPanelState();
}

class _VillesPanelState extends State<_VillesPanel> {
  final PlacesApiService _api = PlacesApiService();
  final _search = TextEditingController();
  List<VillePlace> _rows = [];
  List<GouvernoratPlace> _gouvernorats = [];
  List<SecteurPlace> _secteurs = [];
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.listGouvernorats(),
        _api.listSecteurs(),
        _api.listVilles(page: 0, search: _search.text),
      ]);
      if (!mounted) return;
      final villes = results[2] as VillePage;
      setState(() {
        _gouvernorats = results[0] as List<GouvernoratPlace>;
        _secteurs = results[1] as List<SecteurPlace>;
        _rows = villes.rows;
        _total = villes.total;
        _page = 1;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.s.cannotLoadReference;
      });
    }
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _page = 0;
        _loading = _rows.isEmpty;
      });
    }
    try {
      final page = await _api.listVilles(
        page: reset ? 0 : _page,
        search: _search.text,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _rows = page.rows;
          _page = 1;
        } else {
          _rows = [..._rows, ...page.rows];
          _page += 1;
        }
        _total = page.total;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.s.cannotLoadReference;
      });
    }
  }

  String _govLabel(String? id) {
    for (final g in _gouvernorats) {
      if (g.id == id) return g.label;
    }
    return id ?? '—';
  }

  Future<void> _edit(VillePlace? ville) async {
    final result = await showDialog<_VilleForm>(
      context: context,
      builder: (context) => _VilleFormDialog(
        ville: ville,
        gouvernorats: _gouvernorats.where((g) => g.active).toList(),
        secteurs: _secteurs,
      ),
    );
    if (result == null) return;
    try {
      await _api.saveVille(
        id: ville?.id,
        name: result.name,
        categoryId: result.categoryId,
        secteurId: result.secteurId,
        ordre: result.ordre,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.referenceSaved)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.errorLine('$e'))));
    }
  }

  Future<void> _delete(VillePlace ville) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s.confirmDelete),
        content: Text(ville.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.s.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.removeVille(ville.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.referenceDeleted)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.errorLine('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading && _rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _rows.isEmpty) {
      return ErrorBanner(message: _error!, onRetry: _bootstrap);
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: s.search,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _rows.isEmpty
                  ? ListView(
                      children: [
                        EmptyState(message: s.noVilles, icon: Icons.location_city),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                      itemCount: _rows.length + (_rows.length < _total ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _rows.length) {
                          return TextButton(
                            onPressed: () => _load(reset: false),
                            child: Text(s.loadMore),
                          );
                        }
                        final ville = _rows[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              ville.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${_govLabel(ville.categoryId)}'
                              '${ville.ordre != null ? ' · #${ville.ordre}' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _edit(ville),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(ville),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VilleForm {
  const _VilleForm({
    required this.name,
    required this.categoryId,
    this.secteurId,
    this.ordre,
  });

  final String name;
  final String categoryId;
  final String? secteurId;
  final int? ordre;
}

class _VilleFormDialog extends StatefulWidget {
  const _VilleFormDialog({
    required this.ville,
    required this.gouvernorats,
    required this.secteurs,
  });

  final VillePlace? ville;
  final List<GouvernoratPlace> gouvernorats;
  final List<SecteurPlace> secteurs;

  @override
  State<_VilleFormDialog> createState() => _VilleFormDialogState();
}

class _VilleFormDialogState extends State<_VilleFormDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.ville?.name ?? '');
  late final TextEditingController _ordre = TextEditingController(
    text: widget.ville?.ordre?.toString() ?? '',
  );
  late String? _categoryId = widget.ville?.categoryId;
  late String? _secteurId = widget.ville?.secteurId;

  @override
  void dispose() {
    _name.dispose();
    _ordre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(widget.ville == null ? s.addVille : s.editVille),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: s.city),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              items: widget.gouvernorats
                  .map(
                    (g) => DropdownMenuItem(value: g.id, child: Text(g.label)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              decoration: InputDecoration(labelText: s.governorate),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _secteurId,
              items: [
                DropdownMenuItem(value: null, child: Text(s.noneOption)),
                ...widget.secteurs.map(
                  (sec) => DropdownMenuItem(value: sec.id, child: Text(sec.name)),
                ),
              ],
              onChanged: (v) => setState(() => _secteurId = v),
              decoration: InputDecoration(labelText: s.secteursTab),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ordre,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.routeOrder),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            final categoryId = _categoryId;
            if (name.isEmpty || categoryId == null || categoryId.isEmpty) return;
            final ordreText = _ordre.text.trim();
            final ordre = ordreText.isEmpty ? null : int.tryParse(ordreText);
            if (ordreText.isNotEmpty && ordre == null) return;
            Navigator.pop(
              context,
              _VilleForm(
                name: name,
                categoryId: categoryId,
                secteurId: _secteurId,
                ordre: ordre,
              ),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _SecteursPanel extends StatefulWidget {
  const _SecteursPanel();

  @override
  State<_SecteursPanel> createState() => _SecteursPanelState();
}

class _SecteursPanelState extends State<_SecteursPanel> {
  final PlacesApiService _api = PlacesApiService();
  final _search = TextEditingController();
  List<SecteurPlace> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _api.listSecteurs();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.s.cannotLoadReference;
      });
    }
  }

  Future<void> _edit(SecteurPlace? secteur) async {
    final nameCtrl = TextEditingController(text: secteur?.name ?? '');
    final ordreCtrl =
        TextEditingController(text: secteur?.ordre?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final s = context.s;
        return AlertDialog(
          title: Text(secteur == null ? s.addSecteur : s.editSecteur),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: s.name),
              ),
              TextField(
                controller: ordreCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: s.routeOrder),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.save),
            ),
          ],
        );
      },
    );
    if (saved != true) {
      nameCtrl.dispose();
      ordreCtrl.dispose();
      return;
    }
    final name = nameCtrl.text.trim();
    final ordreText = ordreCtrl.text.trim();
    nameCtrl.dispose();
    ordreCtrl.dispose();
    if (name.isEmpty) return;
    final ordre = ordreText.isEmpty ? null : int.tryParse(ordreText);
    if (ordreText.isNotEmpty && ordre == null) return;
    try {
      await _api.saveSecteur(id: secteur?.id, name: name, ordre: ordre);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.referenceSaved)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.errorLine('$e'))));
    }
  }

  Future<void> _delete(SecteurPlace secteur) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s.confirmDelete),
        content: Text(secteur.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.s.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.removeSecteur(secteur.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.referenceDeleted)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.s.errorLine('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading && _rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _rows.isEmpty) {
      return ErrorBanner(message: _error!, onRetry: _load);
    }
    final q = _search.text.trim().toLowerCase();
    final visible = q.isEmpty
        ? _rows
        : _rows.where((r) => r.name.toLowerCase().contains(q)).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: s.search,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: visible.isEmpty
                  ? ListView(
                      children: [
                        EmptyState(
                          message: s.noSecteurs,
                          icon: Icons.signpost_outlined,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final secteur = visible[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              secteur.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: secteur.ordre == null
                                ? null
                                : Text('#${secteur.ordre}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _edit(secteur),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(secteur),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
