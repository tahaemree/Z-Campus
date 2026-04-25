import 'dart:async';
import 'dart:convert';

import 'package:campus_online/commons/postgrest_helpers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  static const String _highImportanceChannelId = 'high_importance_channel';
  static const String _highImportanceChannelName =
      'High Importance Notifications';
  static const String _highImportanceChannelDescription =
      'Campus Online critical and real-time notifications';
  static const Duration _resumeTokenSyncThrottle = Duration(minutes: 5);

  PushNotificationService({
    FirebaseMessaging? messaging,
    SupabaseClient? supabase,
    GlobalKey<NavigatorState>? navigatorKey,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _supabase = supabase ?? Supabase.instance.client,
        _navigatorKey = navigatorKey,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final SupabaseClient _supabase;
  final GlobalKey<NavigatorState>? _navigatorKey;
  final FlutterLocalNotificationsPlugin _localNotifications;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  AppLifecycleListener? _appLifecycleListener;

  bool _isInitialized = false;
  bool _localNotificationsInitialized = false;
  Map<String, String>? _pendingNavigationPayload;
  DateTime? _lastTokenSyncAt;

  Future<void> initialize() async {
    if (_isInitialized || !isPushMessagingSupportedPlatform()) return;
    _isInitialized = true;

    _bindAuthStateListener();
    _bindTokenRefreshListener();
    _bindIncomingMessageListeners();
    _bindAppLifecycleListener();

    await _initializeLocalNotifications();
    await _configureForegroundPresentation();

    final permission = await requestPermission();
    final isPermissionDenied =
        permission.authorizationStatus == AuthorizationStatus.denied;

    if (isPermissionDenied) {
      debugPrint('Push permission denied by user.');
      return;
    }

    await _fetchAndSyncCurrentToken();
    await _handleInitialMessage();
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
        FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('Foreground push arrived: ${message.messageId}');
      await _showForegroundNotification(message);
    });

    _messageOpenedSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      debugPrint('Push opened app: ${message.messageId}');
      await _handleNotificationTap(message.data);
    });
  }

  void _bindAppLifecycleListener() {
    _appLifecycleListener ??= AppLifecycleListener(
      onResume: () {
        unawaited(_resyncTokenOnResumeIfNeeded());
      },
    );
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      const channel = AndroidNotificationChannel(
        _highImportanceChannelId,
        _highImportanceChannelName,
        description: _highImportanceChannelDescription,
        importance: Importance.high,
      );
      await androidImplementation.createNotificationChannel(channel);
    }

    _localNotificationsInitialized = true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_localNotificationsInitialized) return;

    final remoteNotification = message.notification;
    final title = remoteNotification?.title?.trim();
    final body = remoteNotification?.body?.trim();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final payloadData = message.data.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final payload = payloadData.isEmpty ? null : jsonEncode(payloadData);

    const androidDetails = AndroidNotificationDetails(
      _highImportanceChannelId,
      _highImportanceChannelName,
      channelDescription: _highImportanceChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  Future<void> _handleLocalNotificationTap(
    NotificationResponse response,
  ) async {
    final rawPayload = response.payload;
    if (rawPayload == null || rawPayload.isEmpty) return;

    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map<String, dynamic>) return;
      await _handleNotificationTap(decoded);
    } catch (error) {
      debugPrint('Local notification tap payload parse failed: $error');
    }
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) return;

    debugPrint('Push opened terminated app: ${initialMessage.messageId}');
    await _handleNotificationTap(initialMessage.data);
  }

  Future<void> processPendingNavigation() async {
    final pendingPayload = _pendingNavigationPayload;
    if (pendingPayload == null) return;

    _pendingNavigationPayload = null;
    await _handleNotificationTap(pendingPayload);
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> rawData) async {
    final payload = rawData.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
    final navigatorState = _navigatorKey?.currentState;

    if (navigatorState == null) {
      _pendingNavigationPayload = payload;
      return;
    }

    final notificationId = payload['notification_id'];
    if (notificationId != null && notificationId.isNotEmpty) {
      await _markNotificationAsRead(notificationId);
    }

    final routeName = _routeForPayload(payload);
    final targetId = payload['target_id'];

    if (routeName == '/notifications') {
      navigatorState.pushNamed(
        routeName,
        arguments: notificationId,
      );
      return;
    }

    if (targetId == null || targetId.isEmpty) {
      navigatorState.pushNamed(
        '/notifications',
        arguments: notificationId,
      );
      return;
    }

    navigatorState.pushNamed(routeName, arguments: targetId);
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      await _supabase
          .from(dbNotificationsTable)
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', currentUser.id);
    } catch (error) {
      debugPrint('Push-open read sync failed: $error');
    }
  }

  String _routeForPayload(Map<String, String> payload) {
    switch (payload['type']) {
      case 'event':
        return '/event_details';
      case 'venue':
        return '/venue_details';
      default:
        return '/notifications';
    }
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
      _lastTokenSyncAt = DateTime.now();
      debugPrint('FCM token synced for user ${currentUser.id}');
    } catch (error) {
      debugPrint('FCM token sync failed: $error');
    }
  }

  Future<void> _resyncTokenOnResumeIfNeeded() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final lastTokenSyncAt = _lastTokenSyncAt;
    if (lastTokenSyncAt != null &&
        DateTime.now().difference(lastTokenSyncAt) < _resumeTokenSyncThrottle) {
      return;
    }

    try {
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
    } catch (error) {
      debugPrint('Push notification settings could not be read: $error');
    }

    await _fetchAndSyncCurrentToken();
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
    _appLifecycleListener?.dispose();
    _appLifecycleListener = null;
    _isInitialized = false;
  }
}
