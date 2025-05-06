import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/providers/theme_provider.dart'; // Add this import
import 'package:campus_online/firebase_options.dart';
import 'package:campus_online/screens/venue_detail/venue_detail_screen.dart';
import 'package:campus_online/screens/settings/legal_screens.dart';
import 'package:campus_online/screens/settings/profile_screen.dart';
import 'package:campus_online/screens/auth/login_screen.dart';
import 'package:campus_online/screens/navi_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize and load theme
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
    final auth = FirebaseAuth.instance;
    final isDarkMode = ref.watch(themeProvider).isDarkMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2c2f60)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF2c2f60),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: auth.currentUser != null ? const MainScreen() : const SignIn(),
      routes: {
        '/venue_details': (context) => VenueDetailScreen(
              venueId: ModalRoute.of(context)!.settings.arguments as String,
            ),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/terms_of_service': (context) => const TermsOfServiceScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
