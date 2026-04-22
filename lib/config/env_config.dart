/// Centralized environment configuration.
///
/// Values are injected at build time via `--dart-define`.
/// For production builds, override these using:
/// ```
/// flutter build apk --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>
/// ```
class EnvConfig {
  EnvConfig._();

  // Publishable Supabase credentials are safe to ship in client apps.
  // CI/CD can still override these values via --dart-define.
  static const String _defaultSupabaseUrl =
      'YOUR_SUPABASE_URL';
  static const String _defaultSupabaseAnonKey =
      'YOUR_SUPABASE_ANON_KEY';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultSupabaseAnonKey,
  );

  static String? get configurationError {
    if (supabaseUrl.isEmpty) {
      return 'SUPABASE_URL tanımlanmamış.';
    }

    if (supabaseAnonKey.isEmpty) {
      return 'SUPABASE_ANON_KEY tanımlanmamış.';
    }

    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'SUPABASE_URL geçersiz bir formatta.';
    }

    return null;
  }
}
