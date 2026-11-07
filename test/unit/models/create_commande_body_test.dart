import 'package:allo_coursier_app/models/commande_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildCreateCommandeBody includes web-style place ids when set', () {
    final body = buildCreateCommandeBody(
      expediteurId: '3',
      clientNom: 'Sami',
      clientTelephone: '20111222',
      clientGouvernorat: 'Sfax',
      clientAdresse: 'Rue 1',
      clientVille: 'Sakiet Ezzit',
      produitNom: 'kaak',
      produitPrixTotal: 40,
      produitFragile: false,
      produitOuvrirAvantPaiement: false,
      products: const [
        {'name': 'kaak', 'quantity': 2.0, 'pricePerKilo': 20.0},
      ],
      categoryId: '23',
      villeId: '99',
    );

    expect(body['client_gouvernorat'], 'Sfax');
    expect(body['client_ville'], 'Sakiet Ezzit');
    expect(body['place'], {'categoryId': '23', 'villeId': '99'});
  });

  test('buildCreateCommandeBody omits place when ids missing', () {
    final body = buildCreateCommandeBody(
      expediteurId: '3',
      clientNom: 'Sami',
      clientTelephone: '20111222',
      clientGouvernorat: 'Sfax',
      clientAdresse: 'Rue 1',
      clientVille: 'Sfax',
      produitNom: 'kaak',
      produitPrixTotal: 40,
      produitFragile: false,
      produitOuvrirAvantPaiement: false,
      products: const [],
    );
    expect(body.containsKey('place'), isFalse);
  });
}
