import 'package:allo_coursier_app/domain/gouvernorat_canon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonicalGouvernorat folds accents and aliases', () {
    expect(canonicalGouvernorat('Béja'), 'Beja');
    expect(canonicalGouvernorat('Gabès'), 'Gabes');
    expect(canonicalGouvernorat('mannouba'), 'Manouba');
    expect(canonicalGouvernorat('kef'), 'Le Kef');
    expect(canonicalGouvernorat('Atlantis'), isNull);
  });

  test('localizedPlaceName reads jsonb fr_FR', () {
    expect(localizedPlaceName('Tunis'), 'Tunis');
    expect(
      localizedPlaceName({'fr_FR': 'Sfax', 'en_US': 'Sfax EN'}),
      'Sfax',
    );
  });
}
