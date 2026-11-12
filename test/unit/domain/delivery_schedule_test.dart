import 'package:allo_coursier_app/domain/delivery_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(DeliveryScheduleCache.clear);

  test('Gafsa is served on Monday and Wednesday', () {
    expect(weekdaysFor('Gafsa'), {DateTime.monday, DateTime.wednesday});
    expect(isAllowedDeliveryDay('Gafsa', DateTime(2026, 11, 9)), isTrue); // Mon
    expect(isAllowedDeliveryDay('Gafsa', DateTime(2026, 11, 10)), isFalse); // Tue
    expect(isAllowedDeliveryDay('Gafsa', DateTime(2026, 11, 11)), isTrue); // Wed
  });

  test('Siliana and Le Kef are served on Tuesday', () {
    expect(weekdaysFor('Siliana'), {DateTime.tuesday});
    expect(weekdaysFor('Le Kef'), {DateTime.tuesday});
    expect(isAllowedDeliveryDay('Le Kef', DateTime(2026, 11, 10)), isTrue); // Tue
    expect(isAllowedDeliveryDay('Le Kef', DateTime(2026, 11, 11)), isFalse); // Wed
  });

  test('Ben Arous follows Greater Tunis days (Mon–Sat)', () {
    expect(
      weekdaysFor('Ben Arous'),
      {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
      },
    );
  });

  test('DB cache overrides offline fallback', () {
    DeliveryScheduleCache.replaceAll({
      'Le Kef': {DateTime.friday},
    });
    expect(weekdaysFor('Le Kef'), {DateTime.friday});
    expect(isAllowedDeliveryDay('Le Kef', DateTime(2026, 11, 13)), isTrue); // Fri
  });

  test('nextAllowedDates only returns plan weekdays', () {
    final dates = nextAllowedDates(
      'Gafsa',
      from: DateTime(2026, 11, 9),
      count: 4,
    );
    expect(dates, hasLength(4));
    for (final d in dates) {
      expect(d.weekday == DateTime.monday || d.weekday == DateTime.wednesday, isTrue);
    }
  });
}
