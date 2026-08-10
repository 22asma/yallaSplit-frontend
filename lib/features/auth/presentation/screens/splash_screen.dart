import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated ||
          next.status == AuthStatus.unauthenticated) {
        if (next.status == AuthStatus.authenticated) {
         context.go('/home');
        } else if (next.status == AuthStatus.unauthenticated) {
         context.go('/login');
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.base,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.actionGradient.createShader(bounds),
              child: Text(
                'YallaSplit',
                style: AppTextStyles.display.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Snap the receipt. Share the link.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.violet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

