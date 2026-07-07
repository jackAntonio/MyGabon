import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';

import '../providers/auth_provider.dart';
import '../theme/gabon_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../utils/validators.dart';

/// Écran de connexion (email + mot de passe).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _emailOrPhone;
  String? _password;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'MyGabon',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: GabonTheme.ink,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Content de vous revoir',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GabonTheme.muted,
                      ),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                ],
                CustomTextField(
                  label: 'Email ou téléphone',
                  validator: Validators.validateNotEmpty,
                  onSaved: (v) => _emailOrPhone = v,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Mot de passe',
                  obscureText: true,
                  validator: Validators.validateNotEmpty,
                  onSaved: (v) => _password = v,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetPasswordDialog,
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                const SizedBox(height: 16),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        label: 'Se connecter',
                        onPressed: _submit,
                      ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Pas encore de compte ? Inscrivez-vous'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() {
        _loading = true;
        _error = null;
      });
      final auth = Provider.of<AuthProvider>(context, listen: false);
      try {
        await auth.login(emailOrPhone: _emailOrPhone!, password: _password!);
      } catch (e) {
        setState(() => _error =
            auth.errorMessage ?? e.toString().replaceFirst('Exception: ', ''));
      }
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showResetPasswordDialog() {
    final controller = TextEditingController(text: _emailOrPhone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Votre email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<AuthProvider>(context, listen: false)
                    .resetPassword(email: controller.text.trim());
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Email de réinitialisation envoyé')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
