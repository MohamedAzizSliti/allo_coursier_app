import 'package:allo_coursier_app/models/tarif_model.dart';
import 'package:allo_coursier_app/models/user_model.dart';
import 'package:allo_coursier_app/models/vehicle_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VehicleModel uses matricule/model/livreur', () {
    final v = VehicleModel.fromJson({
      'id': 33,
      'matricule': '249tunis5247',
      'model': 'Fiat/doblo',
      'livreur': 1629,
      'status': 'not available',
    });
    expect(v.id, '33');
    expect(v.matricule, '249tunis5247');
    expect(v.livreur, '1629');
    expect(v.displayName, 'Fiat/doblo - 249tunis5247');
  });

  test('TarifModel maps type/prix/prix_retour', () {
    final t = TarifModel.fromJson({
      'id': '1',
      'type': 'Tunis',
      'prix': 8,
      'prix_retour': 8,
    });
    expect(t.type, 'Tunis');
    expect(t.prix, 8);
    expect(t.prixRetour, 8);
  });

  test('UserModel keeps uid and vehicleId for drivers', () {
    final u = UserModel.fromJson({
      'id': 1629,
      'uid': 7,
      'email': 'livreur@test.com',
      'name': 'Ali',
      'role': 'delivery_person',
      'vehicleId': 33,
    });
    expect(u.id, '1629');
    expect(u.uid, '7');
    expect(u.vehicleId, '33');
    expect(u.identityIds, {'1629', '7'});
  });

  test('UserModel maps montant_disponible', () {
    final u = UserModel.fromJson({
      'id': 203,
      'email': 'a@b.c',
      'name': 'Mouna',
      'role': 'business_client',
      'montant_disponible': 12.5,
      'montant_paye': 40,
      'montant_reste': 25.5,
    });
    expect(u.id, '203');
    expect(u.montantDisponible, 12.5);
    expect(u.montantPaye, 40);
    expect(u.montantReste, 25.5);
    expect(u.needsCompletion, isTrue);
  });

  test('UserModel parses montant_disponible from a string', () {
    final u = UserModel.fromJson({
      'id': 8,
      'email': '',
      'name': 'verona',
      'role': 'business_client',
      'montant_disponible': '42.50',
    });
    expect(u.montantDisponible, 42.5);
  });

  test('UserModel unwraps nested auth/me user payload', () {
    final u = UserModel.fromJson({
      'user': {
        'id': 8,
        'name': 'verona',
        'email': 's@x.tn',
        'role': 'business_client',
        'phone': null,
        'address': null,
      },
    });
    expect(u.id, '8');
    expect(u.name, 'verona');
    expect(u.role, 'business_client');
  });

  test('UserModel.mergedWith fills blank fields from the other user', () {
    const remote = UserModel(
      id: '',
      email: '',
      name: '',
      role: 'business_client',
    );
    const local = UserModel(
      id: '8',
      email: '',
      name: 'verona',
      role: 'business_client',
      phone: '55555555',
      address: 'EZREZREZER',
      city: 'zaghouan',
      gouvernorat: 'Zaghouan',
      company: 'verona',
      cin: '111111111',
    );
    final merged = remote.mergedWith(local);
    expect(merged.id, '8');
    expect(merged.name, 'verona');
    expect(merged.phone, '55555555');
    expect(merged.company, 'verona');
    expect(merged.cin, '111111111');
  });

  test('UserModel keeps extra GET fields and completion extras', () {
    final u = UserModel.fromJson({
      'id': 8,
      'name': 'Shop',
      'email': 's@x.tn',
      'role': 'business_client',
      'phone': '22123456',
      'address': 'Zaghouan',
      'ville': 'Zaghouan',
      'gouvernorat': 'Zaghouan',
      'company': 'Allo Shop',
      'cin': '12345678',
      'odoo_id': 41,
    });
    expect(u.needsCompletion, isFalse);
    expect(u.city, 'Zaghouan');
    expect(u.company, 'Allo Shop');
    expect(u.extra['odoo_id'], 41);
    expect(u.toLocalCard()['name'], 'Shop');
    expect(u.toProfileBody().containsKey('name'), isFalse);
  });

  test('UserModel reads must_change_password', () {
    final u = UserModel.fromJson({
      'id': 8,
      'name': 'verona',
      'email': 's@x.tn',
      'role': 'business_client',
      'must_change_password': true,
    });
    expect(u.mustChangePassword, isTrue);
  });
}
