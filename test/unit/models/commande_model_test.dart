import 'package:allo_coursier_app/models/commande_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson maps flat API fields and HT display id', () {
    final commande = CommandeModel.fromJson({
      'id': 83678,
      'client_nom': 'Ali',
      'client_telephone': '56460555',
      'client_gouvernorat': 'Bizerte',
      'client_adresse': 'rtas jbal',
      'client_ville': 'Ras Jebel',
      'produit_nom': '2.5kg kaak',
      'produit_prix_total': 103,
      'produit_fragile': true,
      'produit_ouvrir_avant_paiement': false,
      'produit_list': [
        {'name': '2.5kg kaak', 'quantity': 1, 'pricePerKilo': 103},
      ],
      'expediteur_id': '203',
      'expediteur_name': 'mouna',
      'livreur_id': '1629',
      'vehicle_id': '33',
      'status': 'En cours',
      'paid': false,
      'livraison': 'Pickup',
      'frais_livraison': 8,
      'date': '2026-10-02T09:07:09.517157',
    });

    expect(commande.id, '83678');
    expect(commande.displayId, 'HT83678');
    expect(commande.clientNom, 'Ali');
    expect(commande.produitPrixTotal, 103);
    expect(commande.fraisLivraison, 8);
    expect(commande.totalDue, 111);
    expect(commande.produitList, isNotEmpty);
    expect(commande.produitPrixTotal.toStringAsFixed(2), '103.00');
  });

  test('fromJson accepts paid as 1 and non-string names', () {
    final commande = CommandeModel.fromJson({
      'id': '9',
      'client_nom': 12,
      'paid': 1,
      'produit_fragile': 'true',
      'status': 'Livrer',
      'produit_list': [
        {'name': 'box'},
        'skip-me',
      ],
    });
    expect(commande.paid, isTrue);
    expect(commande.clientNom, '12');
    expect(commande.produitFragile, isTrue);
    expect(commande.produitList, hasLength(1));
  });

  test('buildCreateCommandeBody includes expediteur_id and drops empty rows', () {
    final body = buildCreateCommandeBody(
      expediteurId: '203',
      clientNom: ' amen ',
      clientTelephone: '58766666',
      clientGouvernorat: 'Medenine',
      clientAdresse: 'mednin',
      clientVille: 'mednin',
      produitNom: '',
      produitPrixTotal: 855,
      produitFragile: false,
      produitOuvrirAvantPaiement: true,
      products: [
        {'name': '', 'quantity': 0.0, 'pricePerKilo': 0.0},
        {'name': 'kaak', 'quantity': 10, 'pricePerKilo': 40},
        {'name': 'balewa', 'quantity': 7, 'pricePerKilo': 65},
      ],
    );

    expect(body['expediteur_id'], '203');
    expect(body['client_nom'], 'amen');
    expect(body['produit_nom'], 'kaak, balewa');
    expect(body['produit_ouvrir_avant_paiement'], isTrue);
    expect(body['produit_list'], [
      {'name': 'kaak', 'quantity': 10.0, 'pricePerKilo': 40.0},
      {'name': 'balewa', 'quantity': 7.0, 'pricePerKilo': 65.0},
    ]);
  });

  test('unpaidDeliveredTotal sums Livrer/Livré unpaid parcels', () {
    const rows = [
      CommandeModel(id: '1', status: 'Livrer', paid: false, produitPrixTotal: 20),
      CommandeModel(id: '2', status: 'Livré', paid: false, produitPrixTotal: 15),
      CommandeModel(id: '3', status: 'Livrer', paid: true, produitPrixTotal: 99),
      CommandeModel(id: '4', status: 'En cours', paid: false, produitPrixTotal: 40),
    ];
    expect(unpaidDeliveredTotal(rows), 35);
  });
}
