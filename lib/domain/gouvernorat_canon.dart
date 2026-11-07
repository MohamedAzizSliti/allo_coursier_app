/// Canonical gouvernorat labels — keep in sync with web `GOUVERNORATS`.
const kCanonicalGouvernorats = <String>[
  'Ariana',
  'Beja',
  'Ben Arous',
  'Bizerte',
  'Gabes',
  'Gafsa',
  'Jendouba',
  'Kairouan',
  'Kasserine',
  'Kébili',
  'Le Kef',
  'Mahdia',
  'Manouba',
  'Medenine',
  'Monastir',
  'Nabeul',
  'Sfax',
  'Sidi Bouzid',
  'Siliana',
  'Sousse',
  'Tataouine',
  'Tozeur',
  'Tunis',
  'Zaghouan',
];

const _aliases = <String, String>{
  'mannouba': 'Manouba',
  'la manouba': 'Manouba',
  'kef': 'Le Kef',
};

String _fold(String raw) {
  final normalized = raw
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  // Strip common Latin diacritics without depending on ICU.
  const from = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñé';
  const to = 'aaaaaaeeeeiiiiooooouuuuyycne';
  final buffer = StringBuffer();
  for (final rune in normalized.runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString();
}

/// Odoo category label → app gouvernorat, or null when unrecognized.
String? canonicalGouvernorat(String raw) {
  final key = _fold(raw);
  if (_aliases.containsKey(key)) return _aliases[key];
  for (final name in kCanonicalGouvernorats) {
    if (_fold(name) == key) return name;
  }
  return null;
}

/// `helpdesk_ticket_category.name` may be a string or `{fr_FR, en_US}` jsonb.
String localizedPlaceName(dynamic value) {
  if (value is String) return value.trim();
  if (value is Map) {
    final fr = value['fr_FR']?.toString().trim();
    if (fr != null && fr.isNotEmpty) return fr;
    final en = value['en_US']?.toString().trim();
    if (en != null && en.isNotEmpty) return en;
    for (final entry in value.values) {
      final s = entry?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
  }
  return '';
}
