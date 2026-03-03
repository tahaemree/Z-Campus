/// Centralized environment configuration.
///
/// Values are injected at build time via `--dart-define`.
/// For production builds, override these using:
/// ```
/// flutter build apk --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>
/// ```
class EnvConfig {
  EnvConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
}
