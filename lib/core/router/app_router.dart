import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yallasplit_app/features/addition/presentation/screens/review_items_screen.dart';
import 'package:yallasplit_app/features/addition/presentation/screens/scan_receipt_screen.dart';
import 'package:yallasplit_app/features/addition/presentation/screens/share_split_screen.dart';
import 'package:yallasplit_app/features/auth/presentation/screens/change_password_screen.dart';
import 'package:yallasplit_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:yallasplit_app/features/auth/presentation/screens/login_screen.dart';
import 'package:yallasplit_app/features/auth/presentation/screens/register_screen.dart';
import 'package:yallasplit_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:yallasplit_app/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:yallasplit_app/features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/addition/presentation/screens/home_screen.dart';
import '../../features/addition/presentation/screens/join_addition_screen.dart';
import '../../features/addition/presentation/screens/payment_result_screen.dart';
import '../../features/addition/presentation/screens/addition_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
  GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
  GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
  GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
  GoRoute(path: '/verify-email', builder: (context, state) {
    final token = state.uri.queryParameters['token'];
    return VerifyEmailScreen(token: token);
  }),
  GoRoute(path: '/reset-password', builder: (context, state) {
    final token = state.uri.queryParameters['token'];
    return ResetPasswordScreen(token: token);
  }),
  GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  GoRoute(path: '/scan-receipt', builder: (context, state) => const ScanReceiptScreen()),
  GoRoute(path: '/review-items', builder: (context, state) => const ReviewItemsScreen()),
  GoRoute(
    path: '/addition/:id/share',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      final montant = double.tryParse(state.uri.queryParameters['montant'] ?? '');
      return ShareSplitScreen(additionId: id, montantTotal: montant);
    },
  ),
  GoRoute(
    path: '/pay/success',
    builder: (context, state) {
      return PaymentResultScreen(
        success: true,
        sessionId: state.uri.queryParameters['session_id'],
        token: state.uri.queryParameters['token'],
      );
    },
  ),
  GoRoute(
    path: '/pay/cancel',
    builder: (context, state) {
      return PaymentResultScreen(
        success: false,
        token: state.uri.queryParameters['token'],
      );
    },
  ),
  GoRoute(
    path: '/pay/:token',
    builder: (context, state) {
      final token = state.pathParameters['token']!;
      return JoinAdditionScreen(token: token);
    },
  ),
  GoRoute(
  path: '/addition/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return AdditionDetailScreen(additionId: id);
  },
),
  GoRoute(path: '/change-password', builder: (context, state) => const ChangePasswordScreen()),
],
  );
});