import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/core/widgets/gradient_button.dart';
import 'package:yallasplit_app/core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    final ok = await ref.read(authNotifierProvider.notifier).changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe modifié avec succès')),
      );
      context.pop();
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Échec du changement de mot de passe')),
      );
    }
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Changer le mot de passe', style: AppTextStyles.display.copyWith(fontSize: 26)),
                const SizedBox(height: 8),
                Text(
                  'Entre ton mot de passe actuel puis choisis-en un nouveau.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _currentController,
                  label: 'MOT DE PASSE ACTUEL',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _newController,
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
                  label: 'CONFIRMER LE NOUVEAU MOT DE PASSE',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value != _newController.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                GradientButton(
                  label: 'Modifier le mot de passe',
                  isLoading: _isLoading,
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