import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campus_online/config/env_config.dart';
import 'package:campus_online/providers/theme_provider.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/screens/venue_detail/venue_detail_screen.dart';
import 'package:campus_online/screens/settings/legal_screens.dart';
import 'package:campus_online/screens/settings/profile_screen.dart';
import 'package:campus_online/screens/auth/login_screen.dart';
import 'package:campus_online/screens/navi_bar.dart';
import 'package:campus_online/config/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Initialization failed: $e');
  }

  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadTheme();

  runApp(ProviderScope(
    overrides: [
      themeProvider.overrideWith((ref) => themeNotifier),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider).isDarkMode;
    // Watch auth state stream so UI reacts to login/logout/token changes
    final authAsync = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Online',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: authAsync.when(
        data: (_) {
          // Check current session after any auth state change
          final session = Supabase.instance.client.auth.currentSession;
          return session != null ? const MainScreen() : const SignIn();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SignIn(),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/venue_details':
            final venueId = settings.arguments as String?;
            if (venueId == null || venueId.isEmpty) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Invalid venue ID')),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => VenueDetailScreen(venueId: venueId),
            );
          case '/privacy_policy':
            return MaterialPageRoute(
                builder: (_) => const PrivacyPolicyScreen());
          case '/terms_of_service':
            return MaterialPageRoute(
                builder: (_) => const TermsOfServiceScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          default:
            return null;
        }
      },
    );
  }
}
