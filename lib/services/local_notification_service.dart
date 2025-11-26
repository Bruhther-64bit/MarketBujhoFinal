import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'price_drop_channel';
  static const String _channelName = 'Price Drop Notifications';
  static const String _channelDescription =
      'Notifications when your wishlist items drop in price';

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  /// Call once at app start (in main.dart).
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(initSettings);

    // Create notification channel on Android
    final androidSpecific = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidSpecific?.createNotificationChannel(_channel);
  }

  /// Request notification permission on Android 13+ (will no-op on lower).
  static Future<void> _requestPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return;

    await Permission.notification.request();
  }

  /// Simple summary notification for price drop demo.
  static Future<void> showPriceDropSummary({
    required int changedCount,
  }) async {
    if (changedCount <= 0) return;

    await _requestPermission();

    final title = changedCount == 1
        ? 'Price drop on 1 wishlist item'
        : 'Price drop on $changedCount wishlist items';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Price drop',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
      title,
      'Open MarketBujho to see updated prices.',
      details,
    );
  }
}