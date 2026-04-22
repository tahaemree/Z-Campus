import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool isPushMessagingSupportedPlatform() {
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

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    SupabaseClient? supabase,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _supabase = supabase ?? Supabase.instance.client;

  final FirebaseMessaging _messaging;
  final SupabaseClient _supabase;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized || !isPushMessagingSupportedPlatform()) return;
    _isInitialized = true;

    _bindAuthStateListener();
    _bindTokenRefreshListener();
    _bindIncomingMessageListeners();

    await _configureForegroundPresentation();

    final permission = await requestPermission();
    final isPermissionDenied =
        permission.authorizationStatus == AuthorizationStatus.denied;

    if (isPermissionDenied) {
      debugPrint('Push permission denied by user.');
      return;
    }

    await _fetchAndSyncCurrentToken();
  }

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
  }

  Future<void> _configureForegroundPresentation() async {
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error) {
      debugPrint('Foreground presentation setup skipped: $error');
    }
  }

  Future<void> _fetchAndSyncCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      await _syncTokenWithSupabaseIfSignedIn(token);
    } catch (error) {
      debugPrint('FCM token could not be fetched: $error');
    }
  }

  void _bindTokenRefreshListener() {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
      (token) async {
        await _syncTokenWithSupabaseIfSignedIn(token);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM token refresh listener error: $error');
      },
    );
  }

  void _bindAuthStateListener() {
    _authStateSubscription ??= _supabase.auth.onAuthStateChange.listen(
      (authState) async {
        switch (authState.event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.initialSession:
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.userUpdated:
          case AuthChangeEvent.passwordRecovery:
            await _fetchAndSyncCurrentToken();
            break;
          case AuthChangeEvent.signedOut:
            await _unregisterCurrentToken();
            break;
          case AuthChangeEvent.mfaChallengeVerified:
          default:
            break;
        }
      },
    );
  }

  void _bindIncomingMessageListeners() {
    _foregroundMessageSubscription ??=
        FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground push arrived: ${message.messageId}');
    });

    _messageOpenedSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Push opened app: ${message.messageId}');
    });
  }

  Future<void> _syncTokenWithSupabaseIfSignedIn(String? token) async {
    final trimmedToken = token?.trim();
    if (trimmedToken == null || trimmedToken.isEmpty) return;

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      debugPrint('FCM token captured but user is not signed in yet.');
      return;
    }

    try {
      await _supabase.rpc(
        'register_push_token',
        params: {
          'p_token': trimmedToken,
          'p_platform': _platformName,
          'p_device_locale':
              WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
        },
      );
      debugPrint('FCM token synced for user ${currentUser.id}');
    } catch (error) {
      debugPrint('FCM token sync failed: $error');
    }
  }

  Future<void> _unregisterCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      final trimmedToken = token?.trim();
      if (trimmedToken == null || trimmedToken.isEmpty) return;

      await _supabase.rpc(
        'unregister_push_token',
        params: {'p_token': trimmedToken},
      );
      debugPrint('FCM token unregistered successfully.');
    } catch (error) {
      debugPrint('FCM token unregister failed: $error');
    }
  }

  String get _platformName {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'unknown';
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _authStateSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    _isInitialized = false;
  }
}
