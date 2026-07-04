import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static String? _pendingPayload;
  static Function(String?)? _onNotificationClick;

  static Function(String?)? get onNotificationClick => _onNotificationClick;

  static set onNotificationClick(Function(String?)? callback) {
    _onNotificationClick = callback;
    if (callback != null && _pendingPayload != null) {
      final payload = _pendingPayload;
      _pendingPayload = null;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_onNotificationClick != null) {
          _onNotificationClick!(payload);
        }
      });
    }
  }

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (_onNotificationClick != null) {
          _onNotificationClick!(response.payload);
        } else {
          _pendingPayload = response.payload;
        }
      },
    );

    // Request permissions for Android 13+
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  static bool _isLaunchNotificationHandled = false;

  Future<void> checkLaunchNotification(Function(String?) onLaunch) async {
    if (_isLaunchNotificationHandled) return;
    
    final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      _isLaunchNotificationHandled = true;
      onLaunch(details.notificationResponse?.payload);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'inventory_alerts_channel',
      'Alertas de Inventario',
      channelDescription: 'Canal para alertas de stock crítico y movimientos',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: 'open_notifications',
    );
  }
}
