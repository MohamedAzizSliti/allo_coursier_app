import 'gouvernorat_canon.dart';

/// One departure day in the weekly delivery plan (offline fallback / dashboard).
class DeliveryDayPlan {
  const DeliveryDayPlan({
    required this.weekday,
    required this.gouvernorats,
  });

  /// [DateTime.monday] … [DateTime.saturday].
  final int weekday;
  final List<String> gouvernorats;
}

/// Greater Tunis — served on every Tunis departure day.
const _grandTunis = <String>[
  'Tunis',
  'Ariana',
  'Ben Arous',
  'Manouba',
  'Zaghouan',
];

/// Offline fallback when `delivery_weekdays` RPC is unavailable.
/// Keep in sync with `app.apply_delivery_weekdays()` migration seed.
const kWeeklyDeliveryPlan = <DeliveryDayPlan>[
  DeliveryDayPlan(
    weekday: DateTime.monday,
    gouvernorats: [
      ..._grandTunis,
      'Kasserine',
      'Sidi Bouzid',
      'Sfax',
      'Kairouan',
      'Gafsa',
    ],
  ),
  DeliveryDayPlan(
    weekday: DateTime.tuesday,
    gouvernorats: [..._grandTunis, 'Nabeul', 'Le Kef', 'Siliana'],
  ),
  DeliveryDayPlan(
    weekday: DateTime.wednesday,
    gouvernorats: [
      ..._grandTunis,
      'Gafsa',
      'Tozeur',
      'Kébili',
      'Beja',
      'Jendouba',
    ],
  ),
  DeliveryDayPlan(
    weekday: DateTime.thursday,
    gouvernorats: [..._grandTunis, 'Sousse', 'Monastir'],
  ),
  DeliveryDayPlan(
    weekday: DateTime.friday,
    gouvernorats: [
      ..._grandTunis,
      'Mahdia',
      'Kairouan',
      'Gabes',
      'Tataouine',
      'Medenine',
    ],
  ),
  DeliveryDayPlan(
    weekday: DateTime.saturday,
    gouvernorats: [..._grandTunis, 'Bizerte'],
  ),
];

/// Runtime schedule from DB (`public.delivery_weekdays`). Empty until loaded.
class DeliveryScheduleCache {
  DeliveryScheduleCache._();

  static Map<String, Set<int>> _byGouvernorat = {};

  static bool get isLoaded => _byGouvernorat.isNotEmpty;

  static void replaceAll(Map<String, Set<int>> next) {
    _byGouvernorat = {
      for (final e in next.entries)
        if (e.key.trim().isNotEmpty && e.value.isNotEmpty) e.key: {...e.value},
    };
  }

  static void clear() => _byGouvernorat = {};

  static Set<int>? lookup(String gouvernorat) {
    final canon = canonicalGouvernorat(gouvernorat) ?? gouvernorat.trim();
    if (canon.isEmpty) return null;
    return _byGouvernorat[canon];
  }
}

Set<int> _fallbackWeekdays(String canon) {
  final days = <int>{};
  for (final plan in kWeeklyDeliveryPlan) {
    if (plan.gouvernorats.any((g) => g == canon)) {
      days.add(plan.weekday);
    }
  }
  return days;
}

/// Weekdays (1=Mon … 7=Sun) when [gouvernorat] is served.
/// Prefers DB cache; falls back to [kWeeklyDeliveryPlan].
Set<int> weekdaysFor(String gouvernorat) {
  final canon = canonicalGouvernorat(gouvernorat) ?? gouvernorat.trim();
  if (canon.isEmpty) return const {};
  return DeliveryScheduleCache.lookup(canon) ?? _fallbackWeekdays(canon);
}

bool isAllowedDeliveryDay(String gouvernorat, DateTime date) {
  final days = weekdaysFor(gouvernorat);
  if (days.isEmpty) return false;
  return days.contains(date.weekday);
}

/// Prefer place weekdays (web parity); fall back to gouvernorat plan.
Set<int> weekdaysForPlace(List<int> placeWeekdays, String gouvernorat) {
  if (placeWeekdays.isNotEmpty) return placeWeekdays.toSet();
  return weekdaysFor(gouvernorat);
}

bool isAllowedDeliveryDayFor(Set<int> days, DateTime date) {
  if (days.isEmpty) return false;
  return days.contains(date.weekday);
}

/// Next calendar dates (local) that match the plan, starting from [from].
List<DateTime> nextAllowedDates(
  String gouvernorat, {
  DateTime? from,
  int count = 14,
  int lookAheadDays = 60,
}) {
  final start = from ?? DateTime.now();
  final day = DateTime(start.year, start.month, start.day);
  final out = <DateTime>[];
  for (var i = 0; i < lookAheadDays && out.length < count; i++) {
    final candidate = day.add(Duration(days: i));
    if (isAllowedDeliveryDay(gouvernorat, candidate)) {
      out.add(candidate);
    }
  }
  return out;
}

String weekdayLabelAr(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'الاثنين';
    case DateTime.tuesday:
      return 'الثلاثاء';
    case DateTime.wednesday:
      return 'الأربعاء';
    case DateTime.thursday:
      return 'الخميس';
    case DateTime.friday:
      return 'الجمعة';
    case DateTime.saturday:
      return 'السبت';
    case DateTime.sunday:
      return 'الأحد';
    default:
      return '';
  }
}

String weekdayLabelFr(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Lundi';
    case DateTime.tuesday:
      return 'Mardi';
    case DateTime.wednesday:
      return 'Mercredi';
    case DateTime.thursday:
      return 'Jeudi';
    case DateTime.friday:
      return 'Vendredi';
    case DateTime.saturday:
      return 'Samedi';
    case DateTime.sunday:
      return 'Dimanche';
    default:
      return '';
  }
}

/// Human-readable served days for a gouvernorat (comma-separated).
String servedDaysLabel(String gouvernorat, {required bool arabic}) {
  final days = weekdaysFor(gouvernorat).toList()..sort();
  if (days.isEmpty) return '';
  return days
      .map((d) => arabic ? weekdayLabelAr(d) : weekdayLabelFr(d))
      .join(arabic ? '، ' : ', ');
}

String gouvernoratsLabelAr(List<String> gouvernorats) {
  const ar = <String, String>{
    'Ariana': 'أريانة',
    'Beja': 'باجة',
    'Ben Arous': 'بن عروس',
    'Bizerte': 'بنزرت',
    'Gabes': 'قابس',
    'Gafsa': 'قفصة',
    'Jendouba': 'جندوبة',
    'Kairouan': 'قيروان',
    'Kasserine': 'القصرين',
    'Kébili': 'قبلي',
    'Le Kef': 'الكاف',
    'Mahdia': 'مهدية',
    'Manouba': 'منوبة',
    'Medenine': 'مدنين',
    'Monastir': 'منستير',
    'Nabeul': 'الوطن القبلي',
    'Sfax': 'صفاقس',
    'Sidi Bouzid': 'سيدي بوزيد',
    'Siliana': 'سليانة',
    'Sousse': 'سوسة',
    'Tataouine': 'تطاوين',
    'Tozeur': 'توزر',
    'Tunis': 'تونس',
    'Zaghouan': 'زغوان',
  };
  return gouvernorats.map((g) => ar[g] ?? g).join('، ');
}
