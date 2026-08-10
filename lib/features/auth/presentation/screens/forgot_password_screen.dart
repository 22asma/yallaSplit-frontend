import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/core/widgets/gradient_button.dart';
import 'package:yallasplit_app/core/widgets/app_text_field.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    await ref.read(authNotifierProvider.notifier).forgotPassword(
          _emailController.text.trim(),
        );
    setState(() {
      _isLoading = false;
      _sent = true; // le backend renvoie toujours un message générique, succès ou non
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        elevation: 0,
        leading: const BackButton(color: AppColors.text),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _sent ? _buildSuccessView() : _buildFormView(),
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
          const SizedBox(height: 24),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.actionGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_reset, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 24),
          Text('Mot de passe oublié ?', style: AppTextStyles.display.copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          Text(
            'Indique ton email, on t\'envoie un lien pour le réinitialiser.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _emailController,
            label: 'EMAIL',
            hint: 'sami.tounsi@gmail.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email requis';
              if (!value.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Envoyer le lien',
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
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppColors.moneyGreen, size: 32),
        ),
        const SizedBox(height: 24),
        Text('Email envoyé', style: AppTextStyles.display.copyWith(fontSize: 26)),
        const SizedBox(height: 8),
        Text(
          'Si un compte existe avec cet email, un lien de réinitialisation vient d\'être envoyé. Vérifie ta boîte mail.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 32),
        GradientButton(
          label: 'Retour à la connexion',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}