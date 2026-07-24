import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_store.dart';

/// Surfaces a real device notification (a heads-up banner + sound) the moment a
/// new in-app alert arrives over the realtime channel — so the member is pinged
/// even while they're on another screen or another app entirely.
///
/// It honours the on-device "Push notifications" preference from Settings, and
/// is entirely best-effort: every failure is swallowed so a notification hiccup
/// can never disrupt the experience. No-ops on unsupported platforms.
abstract final class PushService {
  static const _channelId = 'nesty_alerts';
  static const _channelName = 'Alerts';
  static const _channelDescription = 'Reservation, visit and account updates.';
  static const _settingsKey = 'user_settings';
  static const _icon = 'ic_stat_nesty';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool _permissionAsked = false;
  static int _nextId = 0;

  /// Initializes the plugin and creates the Android channel. Does NOT prompt
  /// for permission — that's [requestPermission], deferred until the member is
  /// inside the app. Safe to call once at startup.
  static Future<void> init() async {
    if (_ready) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings(_icon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );
      _ready = true;
    } catch (_) {
      // Notifications are a nicety, never a blocker.
    }
  }

  /// Requests the OS notification permission (Android 13+ / iOS). Call once the
  /// member is signed in and inside the app — not at cold start. No-ops after
  /// the first ask (the OS itself won't re-prompt once decided).
  static Future<void> requestPermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    if (!_ready) await init();
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {
      // Denied or unavailable — show() simply won't surface anything.
    }
  }

  /// True unless the member has switched "Push notifications" off in Settings.
  static bool get _enabled {
    final prefs = LocalStore.instance.getJson(_settingsKey);
    return prefs == null || prefs['push'] != false;
  }

  /// Surfaces a heads-up notification, honouring the member's push preference.
  static Future<void> show({required String title, String? body}) async {
    if (!_enabled) return;
    if (!_ready) await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: _nextId++,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: _icon,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (_) {
      // Best-effort only.
    }
  }
}
