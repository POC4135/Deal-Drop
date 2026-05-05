import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'dealdrop_repository.dart';
import 'local_store.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService({
    required DealDropRepository repository,
    required LocalStore localStore,
  }) : _repository = repository,
       _localStore = localStore;

  final DealDropRepository _repository;
  final LocalStore _localStore;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _deepLinkController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  bool _initialized = false;

  Stream<String> get deepLinks => _deepLinkController.stream;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initializeLocalNotifications();
      await _captureInitialMessage();
      _openedAppSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
        _handleOpenedMessage,
      );
      _initialized = true;
    } catch (_) {
      return;
    }
  }

  Future<void> registerCurrentDevice() async {
    await initialize();
    if (!_initialized || !_repository.isAuthenticated) {
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
    final enabled =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    final token = enabled ? await messaging.getToken() : null;

    await _registerToken(token: token, notificationsEnabled: enabled);
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) {
      unawaited(_registerToken(token: token, notificationsEnabled: true));
    });

    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
  }

  Future<void> unregisterCurrentDevice() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
    await _openedAppSubscription?.cancel();
    _openedAppSubscription = null;
    if (!_initialized) {
      return;
    }
    final deviceId = await _localStore.deviceId();
    await _repository.unregisterDevice(deviceId: deviceId);
  }

  Future<void> _registerToken({
    required String? token,
    required bool notificationsEnabled,
  }) async {
    final deviceId = await _localStore.deviceId();
    await _repository.registerDevice(
      deviceId: deviceId,
      platform: _platform,
      pushToken: token,
      notificationsEnabled: notificationsEnabled,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _deepLinkController.add(payload);
        }
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['deepLink'],
    );
  }

  Future<void> _captureInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      _handleOpenedMessage(message);
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final deepLink = message.data['deepLink'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      _deepLinkController.add(deepLink);
    }
  }

  String get _platform {
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isMacOS) {
      return 'macos';
    }
    if (Platform.isWindows) {
      return 'windows';
    }
    if (Platform.isLinux) {
      return 'linux';
    }
    return 'android';
  }

  static const _androidChannel = AndroidNotificationChannel(
    'dealdrop_alerts',
    'DealDrop alerts',
    description: 'Deal, contribution, and trust updates.',
    importance: Importance.high,
  );
}
