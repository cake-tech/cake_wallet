import 'dart:io';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationsService {
  PushNotificationsService._();

  factory PushNotificationsService() => _instance;

  static final PushNotificationsService _instance = PushNotificationsService._();
  static Future<dynamic> _onBackgroundMessage(Map<String, dynamic> message) async  {}
  static Future<void> _showNotification(Map<String, dynamic> message) async {
    Map<dynamic, dynamic> alert = <dynamic, dynamic>{};
    String msg = '';
    String title = '';

    if (Platform.isIOS) {
      alert = message['aps']['alert'] as Map<dynamic, dynamic> ?? <dynamic, dynamic>{};
      msg = alert['body'] as String ?? '';
      title = alert['title'] as String ?? '';
    }

    if (Platform.isAndroid) {
      msg = message['notification']['body'] as String ?? '';
      title = message['notification']['title'] as String ?? '';
    }

    await showBar<void>(navigatorKey.currentContext, msg, titleText: title, duration: null);
  }

  final _firebaseMessaging = FirebaseMessaging();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _firebaseMessaging.requestNotificationPermissions();
    _firebaseMessaging.configure(
      onMessage: (message) async => _showNotification(message),
      onLaunch: (message) async => _showNotification(message),
      onResume: (message) async => _showNotification(message),
      onBackgroundMessage: _onBackgroundMessage);

    _initialized = true;
  }
}