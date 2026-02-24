import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';

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
  String? _emailOrPhone;
  String? _password;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create account', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                CustomTextField(
                  label: 'Email or Phone',
                  validator: Validators.validateNotEmpty,
                  onSaved: (v) => _emailOrPhone = v,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  obscureText: true,
                  validator: Validators.validateNotEmpty,
                  onSaved: (v) => _password = v,
                ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        label: 'Register',
                        onPressed: _submit,
                      ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Already have an account? Login'),
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
        await Provider.of<AuthProvider>(context, listen: false)
            .register(emailOrPhone: _emailOrPhone!, password: _password!);
      } catch (e) {
        _error = 'Registration failed';
      }
      setState(() {
        _loading = false;
      });
    }
  }
}
