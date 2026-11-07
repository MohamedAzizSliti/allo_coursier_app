import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/api_client.dart';
import '../services/places_api_service.dart';
import '../theme/app_theme.dart';

/// A ville from the référentiel, with labels stored on the order row.
class PickedVille {
  const PickedVille({
    required this.categoryId,
    required this.villeId,
    required this.gouvernorat,
    required this.ville,
    required this.tarif,
  });

  final String categoryId;
  final String villeId;
  final String gouvernorat;
  final String ville;
  /// Delivery base fee from référentiel (`GouvernoratPlace.tarif`).
  final double tarif;
}

/// Gouvernorat → searchable ville, same flow as web `VillePicker`.
class VillePicker extends StatefulWidget {
  const VillePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final PickedVille? value;
  final ValueChanged<PickedVille?> onChanged;
  final String? errorText;

  @override
  State<VillePicker> createState() => _VillePickerState();
}

class _VillePickerState extends State<VillePicker> {
  static const _maxOptions = 50;

  final PlacesApiService _api = PlacesApiService();
  final _searchController = TextEditingController();

  List<GouvernoratPlace> _gouvernorats = [];
  List<SecteurPlace> _secteurs = [];
  List<VillePlace> _villes = [];
  VillePlace? _picked;
  int _villeTotal = 0;

  String? _categoryId;
  bool _loadingGov = true;
  bool _loadingVilles = false;
  String? _loadError;
  Timer? _debounce;
  int _villesRequestId = 0;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.value?.categoryId;
    _loadCatalog();
  }

  @override
  void didUpdateWidget(covariant VillePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value?.categoryId != oldWidget.value?.categoryId) {
      _categoryId = widget.value?.categoryId;
    }
    if (widget.value == null && oldWidget.value != null) {
      setState(() {
        _picked = null;
        _categoryId = null;
        _villes = [];
        _villeTotal = 0;
        _searchController.clear();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loadingGov = true;
      _loadError = null;
    });
    try {
      // Secteurs are optional labels — don't block gouvernorat/ville pick.
      final secteursFuture = _api.listSecteurs().catchError((_) => <SecteurPlace>[]);
      final all = await _api.listGouvernorats();
      final secteurs = await secteursFuture;
      if (!mounted) return;
      setState(() {
        _gouvernorats = all.where((g) => g.active).toList()
          ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
        _secteurs = secteurs;
        _loadingGov = false;
      });
      if (_categoryId != null && _categoryId!.isNotEmpty) {
        await _loadVilles();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingGov = false;
        _loadError = e is AlloException
            ? e.message
            : context.s.cannotLoadReference;
      });
    }
  }

  Future<void> _loadVilles() async {
    final categoryId = _categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      setState(() {
        _villes = [];
        _villeTotal = 0;
        _loadingVilles = false;
      });
      return;
    }

    final requestId = ++_villesRequestId;
    setState(() => _loadingVilles = true);
    try {
      final page = await _api.listVilles(
        categoryId: categoryId,
        search: _searchController.text,
        pageSize: _maxOptions,
      );
      if (!mounted || requestId != _villesRequestId || categoryId != _categoryId) {
        return;
      }
      setState(() {
        _villes = page.rows;
        _villeTotal = page.total;
        _loadingVilles = false;
      });
    } catch (_) {
      if (!mounted || requestId != _villesRequestId) return;
      setState(() {
        _villes = [];
        _villeTotal = 0;
        _loadingVilles = false;
        _loadError = context.s.cannotLoadReference;
      });
    }
  }

  List<VillePlace> get _options {
    final picked = _picked;
    if (picked == null) return _villes;
    if (_villes.any((v) => v.id == picked.id)) return _villes;
    return [picked, ..._villes];
  }

  void _onCategoryChanged(String? id) {
    setState(() {
      _categoryId = id;
      _picked = null;
      _searchController.clear();
      _villes = [];
      _villeTotal = 0;
    });
    widget.onChanged(null);
    if (id != null && id.isNotEmpty) _loadVilles();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _loadVilles);
  }

  void _onVilleChanged(String? villeId) {
    if (villeId == null || villeId.isEmpty) {
      setState(() => _picked = null);
      widget.onChanged(null);
      return;
    }
    final ville = _options.where((v) => v.id == villeId).firstOrNull;
    final category = _gouvernorats.where((g) => g.id == _categoryId).firstOrNull;
    if (ville == null || category == null) {
      setState(() => _picked = null);
      widget.onChanged(null);
      return;
    }
    setState(() => _picked = ville);
    widget.onChanged(
      PickedVille(
        categoryId: category.id,
        villeId: ville.id,
        gouvernorat: category.label,
        ville: ville.name,
        tarif: category.tarif,
      ),
    );
  }

  String? _secteurName(VillePlace? ville) {
    final id = ville?.secteurId;
    if (id == null || id.isEmpty) return null;
    return _secteurs.where((s) => s.id == id).map((s) => s.name).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loadingGov) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null && _gouvernorats.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_loadError!, style: const TextStyle(color: AppColors.error)),
          TextButton(onPressed: _loadCatalog, child: Text(s.retry)),
        ],
      );
    }

    final hidden = (_villeTotal - _villes.length).clamp(0, 1 << 30);
    final secteur = _secteurName(_picked);
    final detail = _picked == null
        ? null
        : [
            if (secteur != null) '${s.secteursTab} $secteur' else s.noSecteur,
            if (_picked!.ordre != null) '#${_picked!.ordre}',
          ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('gov-$_categoryId'),
          isExpanded: true,
          initialValue: _categoryId,
          decoration: InputDecoration(
            labelText: s.governorate,
            prefixIcon: const Icon(Icons.map_outlined),
          ),
          items: [
            for (final g in _gouvernorats)
              DropdownMenuItem(value: g.id, child: Text(g.label)),
          ],
          onChanged: _onCategoryChanged,
          validator: (_) =>
              widget.value == null ? (widget.errorText ?? s.requiredField) : null,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          enabled: _categoryId != null && _categoryId!.isNotEmpty,
          decoration: InputDecoration(
            hintText: s.searchVilleHint,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('ville-${widget.value?.villeId}-$_loadingVilles'),
          isExpanded: true,
          initialValue: widget.value?.villeId,
          hint: Text(
            _categoryId == null || _categoryId!.isEmpty
                ? s.chooseGovernorateFirst
                : s.chooseVille,
          ),
          decoration: InputDecoration(
            labelText: s.city,
            prefixIcon: const Icon(Icons.location_city_outlined),
            errorText: widget.errorText,
          ),
          items: [
            for (final v in _options)
              DropdownMenuItem(value: v.id, child: Text(v.name)),
          ],
          onChanged: _categoryId == null || _categoryId!.isEmpty
              ? null
              : _onVilleChanged,
          validator: (_) =>
              widget.value == null ? (widget.errorText ?? s.villeRequired) : null,
        ),
        if (_loadingVilles) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (hidden > 0) ...[
          const SizedBox(height: 6),
          Text(
            s.moreVillesHint(hidden),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
        if (detail != null && detail.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ],
    );
  }
}
