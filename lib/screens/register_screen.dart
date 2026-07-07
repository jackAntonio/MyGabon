import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';

import '../providers/auth_provider.dart';
import '../theme/gabon_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../utils/validators.dart';

/// Registration screen allowing new user signup.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _fullName;
  String? _email;
  String? _phoneNumber;
  String? _password;
  bool _loading = false;
  String? _error;
  DateTime? _lastAttempt;

  // Anti-spam minimal côté client : un script appelant directement l'API
  // Supabase contournerait cet écran de toute façon, le vrai rate-limit doit
  // être configuré côté plateforme Supabase Auth (ou un CAPTCHA) ; ceci
  // évite seulement le ré-essai compulsif depuis cette UI.
  static const _cooldown = Duration(seconds: 3);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Rejoindre MyGabon',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: GabonTheme.ink)),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                ],
                CustomTextField(
                  label: 'Nom complet',
                  validator: Validators.validateNotEmpty,
                  onSaved: (v) => _fullName = v,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  validator: Validators.validateEmail,
                  onSaved: (v) => _email = v,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Téléphone',
                  validator: Validators.validatePhone,
                  onSaved: (v) => _phoneNumber = v,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Mot de passe',
                  obscureText: true,
                  validator: Validators.validateNotEmpty,
                  onSaved: (v) => _password = v,
                ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        label: 'S\'inscrire',
                        onPressed: _submit,
                      ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Déjà un compte ? Connectez-vous'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final now = DateTime.now();
    if (_lastAttempt != null && now.difference(_lastAttempt!) < _cooldown) {
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _lastAttempt = now;
      setState(() {
        _loading = true;
        _error = null;
      });
      final auth = Provider.of<AuthProvider>(context, listen: false);
      try {
        final loggedIn = await auth.register(
          email: _email!,
          password: _password!,
          fullName: _fullName!,
          phoneNumber: _phoneNumber,
        );
        // Pas de session après l'inscription : la confirmation email est
        // requise côté Supabase. Sans ce message, l'utilisateur reste sur
        // cet écran sans aucun retour (le compte est pourtant bien créé).
        if (!loggedIn && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Compte créé ! Vérifiez votre email pour confirmer votre compte avant de vous connecter.',
              ),
              duration: Duration(seconds: 6),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _error =
            auth.errorMessage ?? e.toString().replaceFirst('Exception: ', ''));
      }
      if (mounted) setState(() => _loading = false);
    }
  }
}
