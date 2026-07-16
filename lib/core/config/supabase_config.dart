/// Supabase configuration.
///
/// Replace [url] and [anonKey] with your real Supabase project credentials.
/// While these remain placeholders, the app automatically runs in **demo
/// mode**: local mock data sources are used so the whole experience is usable
/// without a backend. As soon as valid credentials are provided, the app wires
/// itself to Supabase instead (see `lib/app/di/injection.dart`).
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://krgxhbsfewzawlbnykem.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_AvRiPszdnQJL1GltRAvzNA_N5NH4Dev',
  );

  /// True only when both values look like real credentials.
  static bool get isConfigured =>
      url.startsWith('http') &&
      anonKey.length > 20 &&
      !anonKey.contains('YOUR_');
}
