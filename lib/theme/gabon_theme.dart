import 'package:flutter/material.dart';

/// Palette et dégradé de fond global aux couleurs du drapeau gabonais
/// (vert / jaune / bleu), appliqués derrière toute l'app via
/// [GabonBackground] plutôt que répétés écran par écran.
class GabonTheme {
  GabonTheme._();

  static const LinearGradient bodyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.22, 0.35, 0.52, 0.58, 0.72, 0.85, 1.0],
    colors: [
      Color(0xFF005A20),
      Color(0xFF008835),
      Color(0xFF00AA44),
      Color(0xFFD4A800),
      Color(0xFFF5C800),
      Color(0xFF1166BB),
      Color(0xFF0055AA),
      Color(0xFF003D88),
    ],
  );

  static const Color accent = Color(0xFFF5C800);
  static const Color accentLight = Color(0xFFFFD93D);
  static const Color ink = Colors.white;
  static const Color muted = Colors.white70;
  static const Color cardBg = Color(0xBF00280F);
  static const Color cardBorder = Color(0x26FFFFFF); // blanc à 15%
}
