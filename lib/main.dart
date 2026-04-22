import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campus_online/config/env_config.dart';
import 'package:campus_online/providers/theme_provider.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/firebase_options.dart';
import 'package:campus_online/screens/events/event_detail_screen.dart';
import 'package:campus_online/screens/notifications/notifications_panel_screen.dart';
import 'package:campus_online/screens/venue_detail/venue_detail_screen.dart';
import 'package:campus_online/screens/settings/contact_us_screen.dart';
import 'package:campus_online/screens/settings/legal_screens.dart';
import 'package:campus_online/screens/settings/profile_screen.dart';
import 'package:campus_online/screens/auth/login_screen.dart';
import 'package:campus_online/screens/navi_bar.dart';
import 'package:campus_online/config/theme/app_theme.dart';
import 'package:campus_online/services/push_notification_service.dart';

ProviderScope _buildRootScope(ThemeNotifier themeNotifier, Widget child) {
  return ProviderScope(
    overrides: [
      themeProvider.overrideWith((ref) => themeNotifier),
    ],
    child: child,
  );
}

final PushNotificationService _pushNotificationService =
    PushNotificationService();

bool _isPushMessagingSupportedPlatform() {
  if (kIsWeb) return false;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return false;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Background push message handled: ${message.messageId}');
}

Future<void> _initializeFirebaseAndPushNotifications() async {
  if (!_isPushMessagingSupportedPlatform()) {
    debugPrint('Push notifications are skipped on this platform.');
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _pushNotificationService.initialize();

    debugPrint('Firebase and FCM initialized successfully');
  } catch (e) {
    debugPrint('Firebase/FCM initialization failed: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadTheme();

  final configError = EnvConfig.configurationError;
  if (configError != null) {
    runApp(_buildRootScope(
      themeNotifier,
      StartupErrorApp(
        title: 'Konfigürasyon Hatası',
        message:
            '$configError\n\nUygulamayı --dart-define ile SUPABASE_URL ve SUPABASE_ANON_KEY vererek çalıştırın.',
      ),
    ));
    return;
  }

  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Initialization failed: $e');
    runApp(_buildRootScope(
      themeNotifier,
      StartupErrorApp(
        title: 'Başlatma Hatası',
        message:
            'Supabase başlatılamadı. Lütfen URL/ANAHTAR değerlerini ve ağ bağlantısını kontrol edin.\n\nHata: $e',
      ),
    ));
    return;
  }

  await _initializeFirebaseAndPushNotifications();

  runApp(_buildRootScope(themeNotifier, const MyApp()));
}

class StartupErrorApp extends StatelessWidget {
  final String title;
  final String message;

  const StartupErrorApp({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Online',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
          case '/event_details':
            final eventId = settings.arguments as String?;
            if (eventId == null || eventId.isEmpty) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Invalid event ID')),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => EventDetailScreen(eventId: eventId),
            );
          case '/notifications':
            return MaterialPageRoute(
              builder: (_) => const NotificationsPanelScreen(),
            );
          case '/privacy_policy':
            return MaterialPageRoute(
                builder: (_) => const PrivacyPolicyScreen());
          case '/terms_of_service':
            return MaterialPageRoute(
                builder: (_) => const TermsOfServiceScreen());
          case '/contact_us':
            return MaterialPageRoute(builder: (_) => const ContactUsScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          default:
            return null;
        }
      },
    );
  }
}
