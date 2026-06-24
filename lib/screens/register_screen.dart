import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';

import '../providers/auth_provider.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../utils/validators.dart';

/// Registration screen allowing new user signup.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Rejoindre MyGabon', style: Theme.of(context).textTheme.titleLarge),
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
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        await Provider.of<AuthProvider>(context, listen: false).register(
          email: _email!,
          password: _password!,
          fullName: _fullName!,
          phoneNumber: _phoneNumber,
        );
      } catch (e) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
      if (mounted) setState(() => _loading = false);
    }
  }
}
