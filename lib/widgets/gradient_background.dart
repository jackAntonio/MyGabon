import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Fond en dégradé doux et clair (blanc -> bleu très pâle -> gris très
/// clair) affiché derrière tout le contenu de l'app, pour une identité
/// visuelle unifiée sur toutes les pages. Utilisé en interne par
/// [AppScaffold] ; le [child] (Scaffold) doit avoir un fond transparent
/// pour laisser apparaître le dégradé.
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgGradientStart,
            AppColors.bgGradientMid,
            AppColors.bgGradientEnd,
          ],
        ),
      ),
      child: child,
    );
  }
}
