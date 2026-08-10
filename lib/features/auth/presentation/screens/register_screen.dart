import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/core/widgets/gradient_button.dart';
import 'package:yallasplit_app/core/widgets/app_text_field.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telephoneController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await ref.read(authNotifierProvider.notifier).register(
          nom: _nomController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          telephone: _telephoneController.text.trim().isEmpty
              ? null
              : _telephoneController.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      _showDialog(
        title: 'Vérifie ta boîte mail',
        message:
            'Un lien de vérification a été envoyé à ${_emailController.text.trim()}. Confirme ton email puis connecte-toi.',
      );
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? "Échec de l'inscription")),
      );
    }
  }

  void _showDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTextStyles.h2),
        content: Text(message, style: AppTextStyles.bodyMuted),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // retourne au login
            },
            child: Text('OK', style: AppTextStyles.body.copyWith(color: AppColors.violet)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Créer un compte', style: AppTextStyles.display.copyWith(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  'Rejoins YallaSplit pour partager tes additions facilement.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 32),

                AppTextField(
                  controller: _nomController,
                  label: 'NOM COMPLET',
                  hint: 'Sami Tounsi',
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                AppTextField(
                  controller: _telephoneController,
                  label: 'TÉLÉPHONE (OPTIONNEL)',
                  hint: '+971501234567',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _passwordController,
                  label: 'MOT DE PASSE',
                  hint: 'Minimum 8 caractères',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Minimum 8 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                GradientButton(
                  label: 'Créer mon compte',
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}