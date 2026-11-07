import 'package:flutter/material.dart';

import '../../domain/delivery_fee.dart';
import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/commande_api_service.dart';
import '../../services/pdf_preview.dart';
import '../../services/places_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parcel_amounts_card.dart';
import '../../widgets/ville_picker.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key, this.staffMode = false});

  /// When true, staff pick an expéditeur then create the order for them.
  final bool staffMode;

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _ProductLine {
  _ProductLine()
      : name = TextEditingController(),
        quantity = TextEditingController(),
        price = TextEditingController();

  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController price;

  Map<String, dynamic> toMap() {
    return {
      'name': name.text.trim(),
      'quantity': double.tryParse(quantity.text.replaceAll(',', '.')) ?? 0,
      'pricePerKilo': double.tryParse(price.text.replaceAll(',', '.')) ?? 0,
    };
  }

  void dispose() {
    name.dispose();
    quantity.dispose();
    price.dispose();
  }
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final CommandeApiService _commandeService = CommandeApiService();
  final UserApiService _userService = UserApiService();

  final _clientNameController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _productNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _senderSearchController = TextEditingController();

  bool _isFragile = false;
  bool _canOpenBeforePay = false;
  double _totalPrice = 0;
  PickedVille? _pickedPlace;
  bool _isSubmitting = false;
  final List<_ProductLine> _lines = [_ProductLine()];

  List<UserModel> _senders = [];
  String? _selectedSenderId;
  bool _loadingSenders = false;

  @override
  void initState() {
    super.initState();
    if (widget.staffMode) _loadSenders();
  }

  Future<void> _loadSenders() async {
    setState(() => _loadingSenders = true);
    try {
      final users = await _userService.listUsers(role: 'business_client');
      if (!mounted) return;
      setState(() {
        _senders = users;
        _loadingSenders = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSenders = false);
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientAddressController.dispose();
    _productNameController.dispose();
    _clientPhoneController.dispose();
    _senderSearchController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _productKg {
    var kg = 0.0;
    for (final item in sanitizeProduitList(_lines.map((l) => l.toMap()).toList())) {
      kg += item['quantity'] as double;
    }
    return kg;
  }

  double get _deliveryFee {
    final place = _pickedPlace;
    if (place == null) return 0;
    return deliveryFeeFor(
      gouvernorat: place.gouvernorat,
      kg: _productKg,
      tarif: place.tarif,
    );
  }

  void _recomputeTotal() {
    var total = 0.0;
    for (final item in sanitizeProduitList(_lines.map((l) => l.toMap()).toList())) {
      total += (item['quantity'] as double) * (item['pricePerKilo'] as double);
    }
    setState(() => _totalPrice = total);
  }

  void _addRow() {
    setState(() {
      _lines.add(_ProductLine());
    });
  }

  void _removeRow(int index) {
    if (_lines.length == 1) {
      _lines.first.name.clear();
      _lines.first.quantity.clear();
      _lines.first.price.clear();
      _recomputeTotal();
      return;
    }
    setState(() {
      _lines.removeAt(index).dispose();
    });
    _recomputeTotal();
  }

  Future<void> _addOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final place = _pickedPlace;
    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.villeRequired)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = widget.staffMode
          ? _selectedSenderId
          : await AlloApi.instance.getStoredUserId();
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.staffMode
                  ? context.s.chooseSender
                  : context.s.notAuthenticated,
            ),
          ),
        );
        return;
      }

      final products = _lines.map((l) => l.toMap()).toList();
      final body = buildCreateCommandeBody(
        expediteurId: userId,
        clientNom: _clientNameController.text,
        clientTelephone: _clientPhoneController.text,
        clientGouvernorat: place.gouvernorat,
        clientAdresse: _clientAddressController.text,
        clientVille: place.ville,
        produitNom: _productNameController.text,
        produitPrixTotal: _totalPrice,
        produitFragile: _isFragile,
        produitOuvrirAvantPaiement: _canOpenBeforePay,
        products: products,
        categoryId: place.categoryId,
        villeId: place.villeId,
      );
      if ((body['produit_list'] as List).isEmpty ||
          (body['produit_nom'] as String).isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.addAtLeastOneProduct)),
        );
        return;
      }

      final created = await _commandeService.createCommande(body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.s.orderAdded),
          action: SnackBarAction(
            label: context.s.print,
            onPressed: () => showPdfPreview(created),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      // Same as web: open the bordereau after create.
      await showPdfPreview(created);

      if (!mounted) return;
      if (widget.staffMode) {
        Navigator.of(context).pop(created);
        return;
      }
      _resetForm();
    } on AlloException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.errorLine(_localizeCreateError(e.message)))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.addOrderError)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _clientNameController.clear();
    _clientAddressController.clear();
    _productNameController.clear();
    _clientPhoneController.clear();
    for (final line in _lines) {
      line.dispose();
    }
    setState(() {
      _totalPrice = 0;
      _isFragile = false;
      _canOpenBeforePay = false;
      _pickedPlace = null;
      _lines
        ..clear()
        ..add(_ProductLine());
    });
  }

  String _localizeCreateError(String message) {
    if (message.toLowerCase().contains('invalides') ||
        message.toLowerCase().contains('invalid')) {
      return context.s.invalidOrderData;
    }
    return message;
  }

  List<UserModel> get _filteredSenders {
    final q = _senderSearchController.text.trim().toLowerCase();
    final matched = q.isEmpty
        ? _senders
        : _senders.where((u) {
            final hay = '${u.name} ${u.phone ?? ''}'.toLowerCase();
            return hay.contains(q);
          });
    final shown = matched.take(50).toList();
    final selected = _senders.where((u) => u.id == _selectedSenderId);
    for (final u in selected) {
      if (!shown.any((s) => s.id == u.id)) shown.insert(0, u);
    }
    return shown;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: widget.staffMode
          ? AppBar(title: Text(s.staffNewOrder))
          : null,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (widget.staffMode) ...[
              _sectionCard(
                title: s.roleSender,
                child: Column(
                  children: [
                    TextField(
                      controller: _senderSearchController,
                      decoration: InputDecoration(
                        hintText: s.searchSenderHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingSenders)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey(_selectedSenderId),
                        initialValue: _selectedSenderId,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: s.chooseSender),
                        items: _filteredSenders
                            .map(
                              (u) => DropdownMenuItem(
                                value: u.id,
                                child: Text(
                                  u.name.trim().isEmpty ? u.id : u.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedSenderId = v),
                        validator: (v) =>
                            v == null || v.isEmpty ? s.requiredField : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _sectionCard(
              title: s.productInfo,
              child: Column(
                children: [
                  _field(
                    _productNameController,
                    s.productName,
                    icon: Icons.inventory_2_outlined,
                    requiredField: false,
                    onChanged: (_) => _recomputeTotal(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.fragile),
                    value: _isFragile,
                    onChanged: (value) => setState(() => _isFragile = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.canOpenBeforePay),
                    value: _canOpenBeforePay,
                    onChanged: (value) => setState(() => _canOpenBeforePay = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: s.productList,
              child: Column(
                children: [
                  for (var i = 0; i < _lines.length; i++) _productCard(i, s),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add),
                    label: Text(s.addProduct),
                  ),
                  const SizedBox(height: 12),
                  ParcelAmountsCard(
                    colisPrice: _totalPrice,
                    deliveryFee: _deliveryFee,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: s.clientInfo,
              child: Column(
                children: [
                  _field(_clientNameController, s.clientNameField, icon: Icons.person_outline),
                  _field(
                    _clientPhoneController,
                    s.phone,
                    icon: Icons.phone_outlined,
                    isPhone: true,
                  ),
                  VillePicker(
                    value: _pickedPlace,
                    onChanged: (place) => setState(() => _pickedPlace = place),
                  ),
                  const SizedBox(height: 12),
                  _field(_clientAddressController, s.address, icon: Icons.home_outlined),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showDeliveryFeesDialog,
              child: Text(s.deliveryFeesNote),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _addOrder,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.submitOrder),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _productCard(int index, AppStrings s) {
    final line = _lines[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.productNumber(index + 1),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: s.removeProduct,
                onPressed: () => _removeRow(index),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
          _field(line.name, s.productName, onChanged: (_) => _recomputeTotal()),
          Row(
            children: [
              Expanded(
                child: _field(
                  line.quantity,
                  s.quantityKg,
                  isNumber: true,
                  onChanged: (_) => _recomputeTotal(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                  line.price,
                  s.pricePerKg,
                  isNumber: true,
                  onChanged: (_) => _recomputeTotal(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    IconData? icon,
    bool isPhone = false,
    bool isNumber = false,
    bool requiredField = true,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textDirection: isNumber || isPhone ? TextDirection.ltr : null,
        keyboardType: isPhone
            ? TextInputType.phone
            : isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
        validator: (value) {
          if (!requiredField) return null;
          return value == null || value.trim().isEmpty ? context.s.requiredField : null;
        },
        onChanged: onChanged,
      ),
    );
  }

  void _showDeliveryFeesDialog() {
    final s = context.s;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(s.feesByGov, textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<GouvernoratPlace>>(
              future: PlacesApiService().listGouvernorats(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final rows = (snap.data ?? [])
                    .where((g) => g.active)
                    .toList()
                  ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
                if (rows.isEmpty) {
                  return Text(s.cannotLoadReference);
                }
                final byFee = <double, List<String>>{};
                for (final g in rows) {
                  byFee.putIfAbsent(g.tarif, () => []).add(g.label);
                }
                final fees = byFee.keys.toList()..sort();
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final fee in fees) ...[
                        Text(
                          '${fee.toStringAsFixed(0)} DT',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(byFee[fee]!.join(' · ')),
                        const Divider(),
                      ],
                      Text(
                        s.extraWeightFee,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(s.close)),
          ],
        );
      },
    );
  }
}

class TunisianGovernorate {
  const TunisianGovernorate(this.apiValue, this.ar, this.fr);

  final String apiValue;
  final String ar;
  final String fr;

  String label(bool arabic) => arabic ? ar : fr;
}

String governorateLabel(String? apiValue, bool arabic) {
  if (apiValue == null || apiValue.trim().isEmpty) return '';
  for (final g in kTunisianGovernorates) {
    if (g.apiValue.toLowerCase() == apiValue.trim().toLowerCase()) {
      return g.label(arabic);
    }
  }
  return apiValue;
}

const kTunisianGovernorates = [
  TunisianGovernorate('Tunis', 'تونس', 'Tunis'),
  TunisianGovernorate('Ariana', 'أريانة', 'Ariana'),
  TunisianGovernorate('Ben Arous', 'بن عروس', 'Ben Arous'),
  TunisianGovernorate('Manouba', 'منوبة', 'Manouba'),
  TunisianGovernorate('Nabeul', 'نابل', 'Nabeul'),
  TunisianGovernorate('Zaghouan', 'زغوان', 'Zaghouan'),
  TunisianGovernorate('Bizerte', 'بنزرت', 'Bizerte'),
  TunisianGovernorate('Beja', 'باجة', 'Béja'),
  TunisianGovernorate('Jendouba', 'جندوبة', 'Jendouba'),
  TunisianGovernorate('Le Kef', 'الكاف', 'Le Kef'),
  TunisianGovernorate('Siliana', 'سليانة', 'Siliana'),
  TunisianGovernorate('Sousse', 'سوسة', 'Sousse'),
  TunisianGovernorate('Monastir', 'المنستير', 'Monastir'),
  TunisianGovernorate('Mahdia', 'المهدية', 'Mahdia'),
  TunisianGovernorate('Kairouan', 'القيروان', 'Kairouan'),
  TunisianGovernorate('Kasserine', 'القصرين', 'Kasserine'),
  TunisianGovernorate('Sidi Bouzid', 'سيدي بوزيد', 'Sidi Bouzid'),
  TunisianGovernorate('Sfax', 'صفاقس', 'Sfax'),
  TunisianGovernorate('Gabes', 'قابس', 'Gabès'),
  TunisianGovernorate('Medenine', 'مدنين', 'Médenine'),
  TunisianGovernorate('Tataouine', 'تطاوين', 'Tataouine'),
  TunisianGovernorate('Gafsa', 'قفصة', 'Gafsa'),
  TunisianGovernorate('Tozeur', 'توزر', 'Tozeur'),
  TunisianGovernorate('Kébili', 'قبلي', 'Kébili'),
];

