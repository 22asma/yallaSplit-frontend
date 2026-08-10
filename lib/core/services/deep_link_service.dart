import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  void init(GoRouter router) {
    // Lien qui a lancé l'app (app fermée)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri, router);
    });

    // Liens reçus pendant que l'app tourne
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri, router);
    });
  }

  void _handleUri(Uri uri, GoRouter router) {
    // On ne garde que le path + query, peu importe le scheme/host
    // (yallasplit://verify-email?token=x ou https://yallasplit.app/verify-email?token=x)
    final path = '/${uri.pathSegments.join('/')}';
    final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
    router.go('$path$query');
  }

  void dispose() {
    _subscription?.cancel();
  }
}