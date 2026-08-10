import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:yallasplit_app/features/notification/data/datasources/notification_api_service.dart';

class PushNotificationService {
  final NotificationApiService _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  PushNotificationService(this._api);

  /// À appeler juste après un login réussi.
  Future<void> initAndRegister() async {
    if (kIsWeb) return; // on gère push mobile uniquement pour l'instant

    final granted = await _requestPermission();
    if (!granted) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _api.registerDeviceToken(
      fcmToken: token,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );

    // Si Firebase régénère le token plus tard, on le renvoie au backend.
    _messaging.onTokenRefresh.listen((newToken) {
      _api.registerDeviceToken(
        fcmToken: newToken,
        platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      );
    });
  }

  /// À appeler juste avant le logout, pour ne plus recevoir de push sur cet appareil.
  Future<void> unregister() async {
    if (kIsWeb) return;
    final token = await _messaging.getToken();
    if (token != null) {
      await _api.removeDeviceToken(token);
    }
  }

  Future<bool> _requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}