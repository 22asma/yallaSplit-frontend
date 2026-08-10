import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:yallasplit_app/features/notification/data/datasources/notification_api_service.dart';
import 'package:yallasplit_app/features/notification/services/push_notification_service.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService(ref.watch(dioClientProvider));
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(notificationApiServiceProvider));
});