/// Public Supabase project settings — same as web `NEXT_PUBLIC_SUPABASE_*`.
///
/// Override at build time:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gbcjpyaqigodvoityrxx.supabase.co',
  );

  /// Publishable anon key (safe in the client, same as web).
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_eKJF-1OwG4C0webadK7ztQ_7h_eNARk',
  );

  static String get restUrl => '$url/rest/v1';
}
