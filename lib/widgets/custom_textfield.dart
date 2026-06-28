import 'package:flutter/material.dart';

/// A modern input field used throughout the app.
/// Pour les champs de mot de passe (`obscureText: true`), affiche un bouton
/// pour basculer la visibilité du texte saisi.
class CustomTextField extends StatefulWidget {
  final String label;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.label,
    this.obscureText = false,
    this.validator,
    this.onSaved,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
      obscureText: _obscured,
      validator: widget.validator,
      onSaved: widget.onSaved,
      keyboardType: widget.keyboardType,
    );
  }
}
