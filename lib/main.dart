import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/services/firebase/auth_service.dart';
import 'package:campus_online/screens/auth/auth_wrapper.dart';
import 'package:campus_online/firebase_options.dart';
import 'package:campus_online/providers/theme_provider.dart';
import 'package:campus_online/config/theme/app_theme.dart';
import 'package:campus_online/screens/venue_detail/venue_detail_screen.dart';
import 'package:campus_online/screens/settings/legal_screens.dart';
import 'package:campus_online/screens/home/explore_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_online/screens/settings/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    ThemeNotifier.initialize(),
    SharedPreferences.getInstance(), // SharedPreferences başlatılıyor
  ]);

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize theme
    ref.read(themeProvider.notifier).loadTheme();

    return const MyApp();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Campus Online',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/venue_details': (context) => VenueDetailScreen(
              venueId: ModalRoute.of(context)!.settings.arguments as String,
            ),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/terms_of_service': (context) => const TermsOfServiceScreen(),
        '/explore': (context) => const ExploreScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
