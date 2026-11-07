/// Immutable user model matching the API schema.
///
/// IDs are numeric strings (e.g. `"203"`). Extra GET keys are kept in [extra]
/// so they are not dropped.
class UserModel {
  final String id;
  final String? uid;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? address;
  final String? city;
  final String? gouvernorat;
  final String? company;
  final String? cin;
  final String? createdAt;
  final double montantDisponible;
  final String? vehicleId;
  final bool mustChangePassword;
  final Map<String, dynamic> extra;

  const UserModel({
    required this.id,
    this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.address,
    this.city,
    this.gouvernorat,
    this.company,
    this.cin,
    this.createdAt,
    this.montantDisponible = 0,
    this.vehicleId,
    this.mustChangePassword = false,
    this.extra = const {},
  });

  Set<String> get identityIds => {
        if (id.trim().isNotEmpty) id.trim(),
        if (uid != null && uid!.trim().isNotEmpty) uid!.trim(),
      };

  bool get needsCompletion {
    if (role != 'business_client') return false;
    return _blank(phone) ||
        _blank(address) ||
        _blank(city) ||
        _blank(gouvernorat);
  }

  static bool _blank(String? value) => value == null || value.trim().isEmpty;

  static double? _num(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  static String? _read(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final nested = json['user'];
    if (nested is Map &&
        json['id'] == null &&
        json['uid'] == null &&
        json['role'] == null) {
      return UserModel.fromJson(Map<String, dynamic>.from(nested));
    }
    const known = {
      'id',
      'uid',
      'email',
      'name',
      'role',
      'phone',
      'address',
      'city',
      'ville',
      'gouvernorat',
      'governorate',
      'company',
      'societe',
      'cin',
      'matricule_fiscale',
      'created_at',
      'createdAt',
      'montant_disponible',
      'montantDisponible',
      'fcm_token',
      'vehicleId',
      'vehicle_id',
      'must_change_password',
      'mustChangePassword',
    };
    final extra = <String, dynamic>{};
    json.forEach((key, value) {
      if (!known.contains(key) && value != null) extra[key] = value;
    });

    return UserModel(
      id: json['id']?.toString() ?? json['uid']?.toString() ?? '',
      uid: json['uid']?.toString(),
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: _read(json, ['phone', 'telephone']),
      address: _read(json, ['address', 'adresse']),
      city: _read(json, ['city', 'ville']),
      gouvernorat: _read(json, ['gouvernorat', 'governorate']),
      company: _read(json, ['company', 'societe']),
      cin: _read(json, ['cin', 'matricule_fiscale']),
      createdAt: _read(json, ['created_at', 'createdAt']),
      montantDisponible: _num(json['montant_disponible']) ??
          _num(json['montantDisponible']) ??
          0.0,
      vehicleId: _read(json, ['vehicleId', 'vehicle_id']),
      mustChangePassword: json['must_change_password'] == true ||
          json['mustChangePassword'] == true,
      extra: extra,
    );
  }

  UserModel copyWith({
    String? phone,
    String? address,
    String? city,
    String? gouvernorat,
    String? company,
    String? cin,
    bool? mustChangePassword,
  }) {
    return UserModel(
      id: id,
      uid: uid,
      email: email,
      name: name,
      role: role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      gouvernorat: gouvernorat ?? this.gouvernorat,
      company: company ?? this.company,
      cin: cin ?? this.cin,
      createdAt: createdAt,
      montantDisponible: montantDisponible,
      vehicleId: vehicleId,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      extra: extra,
    );
  }

  UserModel mergedWith(UserModel other) {
    String pick(String a, String b) => a.trim().isNotEmpty ? a : b;
    String? pickN(String? a, String? b) {
      if (a != null && a.trim().isNotEmpty) return a;
      if (b != null && b.trim().isNotEmpty) return b;
      return a ?? b;
    }

    return UserModel(
      id: pick(id, other.id),
      uid: pickN(uid, other.uid),
      email: pick(email, other.email),
      name: pick(name, other.name),
      role: pick(role, other.role),
      phone: pickN(phone, other.phone),
      address: pickN(address, other.address),
      city: pickN(city, other.city),
      gouvernorat: pickN(gouvernorat, other.gouvernorat),
      company: pickN(company, other.company),
      cin: pickN(cin, other.cin),
      createdAt: pickN(createdAt, other.createdAt),
      montantDisponible:
          montantDisponible != 0 ? montantDisponible : other.montantDisponible,
      vehicleId: pickN(vehicleId, other.vehicleId),
      mustChangePassword: mustChangePassword || other.mustChangePassword,
      extra: {...other.extra, ...extra},
    );
  }

  Map<String, dynamic> toProfileBody() {
    return {
      if (!_blank(phone)) 'phone': phone,
      if (!_blank(address)) 'address': address,
      if (!_blank(city)) 'city': city,
      if (!_blank(gouvernorat)) 'gouvernorat': gouvernorat,
      if (!_blank(company)) 'company': company,
      if (!_blank(cin)) 'cin': cin,
    };
  }

  Map<String, dynamic> toLocalCard() {
    return {
      if (id.trim().isNotEmpty) 'id': id,
      if (name.trim().isNotEmpty) 'name': name,
      if (email.trim().isNotEmpty) 'email': email,
      if (role.trim().isNotEmpty) 'role': role,
      ...toProfileBody(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: $role)';
}
