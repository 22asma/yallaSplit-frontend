import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sert uniquement de "signal" entre l'interceptor Dio et AuthNotifier,
/// pour éviter une dépendance circulaire directe entre dioClientProvider
/// et authNotifierProvider.
class SessionController extends StateNotifier<int> {
  SessionController() : super(0);

  /// Incrémente le compteur -> déclenche les listeners (voir AuthNotifier)
  void notifySessionExpired() => state++;
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, int>((ref) {
  return SessionController();
});