import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/core/widgets/gradient_button.dart';
import 'package:yallasplit_app/core/widgets/app_text_field.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _done = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.token == null || widget.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien invalide')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final ok = await ref.read(authNotifierProvider.notifier).resetPassword(
          token: widget.token!,
          newPassword: _passwordController.text,
        );
    setState(() {
      _isLoading = false;
      _done = ok;
    });

    if (!ok && mounted) {
      final error = ref.read(authNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Échec de la réinitialisation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _done ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text('Nouveau mot de passe', style: AppTextStyles.display.copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          Text('Choisis un nouveau mot de passe pour ton compte.',
              style: AppTextStyles.bodyMuted),
          const SizedBox(height: 32),
          AppTextField(
            controller: _passwordController,
            label: 'NOUVEAU MOT DE PASSE',
            hint: 'Minimum 8 caractères',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: (value) {
              if (value == null || value.length < 8) return 'Minimum 8 caractères';
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _confirmController,
            label: 'CONFIRMER LE MOT DE PASSE',
            hint: 'Retape ton mot de passe',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: (value) {
              if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Réinitialiser',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 60),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.moneyGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline, color: AppColors.moneyGreen, size: 32),
        ),
        const SizedBox(height: 24),
        Text('Mot de passe réinitialisé', style: AppTextStyles.display.copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text('Tu peux maintenant te connecter avec ton nouveau mot de passe.',
            style: AppTextStyles.bodyMuted),
        const SizedBox(height: 32),
        GradientButton(
          label: 'Se connecter',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}