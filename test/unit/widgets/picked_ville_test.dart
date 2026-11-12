import 'package:allo_coursier_app/widgets/ville_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PickedVille keeps référentiel ids and display labels', () {
    const place = PickedVille(
      categoryId: 'g-sfax',
      villeId: 'v-1',
      gouvernorat: 'Sfax',
      ville: 'Sakiet Ezzit',
      tarif: 8,
      weekdays: [2, 5],
    );
    expect(place.categoryId, 'g-sfax');
    expect(place.villeId, 'v-1');
    expect(place.gouvernorat, 'Sfax');
    expect(place.ville, 'Sakiet Ezzit');
    expect(place.tarif, 8);
    expect(place.weekdays, [2, 5]);
  });
}

