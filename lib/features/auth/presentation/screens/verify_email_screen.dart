import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/core/widgets/gradient_button.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String? token;

  const VerifyEmailScreen({super.key, this.token});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

enum _VerifyState { loading, success, error }

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  _VerifyState _state = _VerifyState.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() => _state = _VerifyState.error);
      return;
    }

    final ok = await ref.read(authNotifierProvider.notifier).verifyEmail(widget.token!);
    setState(() => _state = ok ? _VerifyState.success : _VerifyState.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_state == _VerifyState.loading) ...[
                  const CircularProgressIndicator(color: AppColors.violet),
                  const SizedBox(height: 24),
                  Text('Vérification en cours...', style: AppTextStyles.bodyMuted),
                ] else if (_state == _VerifyState.success) ...[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.moneyGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        color: AppColors.moneyGreen, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text('Email vérifié 🎉',
                      style: AppTextStyles.display.copyWith(fontSize: 26)),
                  const SizedBox(height: 8),
                  Text(
                    'Ton compte est activé, tu peux maintenant te connecter.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted,
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Se connecter',
                    onPressed: () => context.go('/login'),
                  ),
                ] else ...[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text('Lien invalide ou expiré',
                      style: AppTextStyles.display.copyWith(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    'Ce lien de vérification n\'est plus valide. Reconnecte-toi pour en recevoir un nouveau.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted,
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Retour à la connexion',
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}