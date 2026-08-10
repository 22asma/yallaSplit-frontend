import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_state.dart';

class AuthTestScreen extends ConsumerStatefulWidget {
  const AuthTestScreen({super.key});

  @override
  ConsumerState<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends ConsumerState<AuthTestScreen> {
  final emailController = TextEditingController(text: 'test@example.com');
  final passwordController = TextEditingController(text: 'Password123!');
  final nomController = TextEditingController(text: 'Test User');

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Auth Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Status: ${authState.status}'),
            if (authState.user != null) Text('User: ${authState.user!.email}'),
            if (authState.errorMessage != null)
              Text(
                'Erreur: ${authState.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      final ok = await authNotifier.register(
                        email: emailController.text,
                        password: passwordController.text,
                        nom: nomController.text,
                      );
                      _showSnack(ok ? 'Inscription OK, vérifie ta console backend pour le lien' : 'Échec inscription');
                    },
              child: const Text('Register'),
            ),
            ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      final ok = await authNotifier.login(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                      _showSnack(ok ? 'Login OK' : 'Échec login');
                    },
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: authState.status == AuthStatus.authenticated
                  ? () async {
                      await authNotifier.logout();
                      _showSnack('Déconnecté');
                    }
                  : null,
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}