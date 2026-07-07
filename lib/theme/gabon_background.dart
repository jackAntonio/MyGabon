import 'package:flutter/material.dart';
import 'gabon_theme.dart';

/// Remplit tout l'écran du dégradé [GabonTheme.bodyGradient]. Monté une
/// seule fois via le `builder` de [MaterialApp] pour que chaque route
/// hérite automatiquement du même fond, sans le répéter manuellement.
class GabonBackground extends StatelessWidget {
  final Widget child;

  const GabonBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: GabonTheme.bodyGradient),
      child: child,
    );
  }
}
