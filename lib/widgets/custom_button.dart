import 'package:flutter/material.dart';

/// A primary button used across the application.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool elevated;

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.elevated = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: elevated
          ? ElevatedButton(onPressed: onPressed, child: Text(label))
          : TextButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
