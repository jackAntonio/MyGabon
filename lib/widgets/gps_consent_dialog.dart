import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Dialogue de consentement affiché avant toute capture GPS pour publication publique.
///
/// Informe l'utilisateur que ses coordonnées précises seront stockées et
/// lisibles par tous les utilisateurs connectés à MyGabon, et lui
/// conseille d'éviter d'utiliser sa position exacte de domicile.
///
/// Retourne [true] si l'utilisateur confirme, [false] ou [null] s'il annule.
class GpsConsentDialog extends StatelessWidget {
  const GpsConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // Icône d'avertissement publique bien visible
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.public_rounded,
          color: AppColors.warning,
          size: 28,
        ),
      ),
      title: Text(
        'Position visible publiquement',
        textAlign: TextAlign.center,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encadré d'avertissement principal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Votre position GPS précise sera enregistrée et visible '
                    'par tous les utilisateurs connectés à MyGabon.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.grey800,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Conseil sur la vie privée
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppColors.info,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Conseil : si vous publiez depuis votre domicile ou un lieu '
                  'privé, préférez capturer votre position depuis une rue ou un '
                  'quartier proche plutôt que votre adresse exacte.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        // Bouton annulation
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        // Bouton confirmation explicite
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Je comprends, continuer'),
        ),
      ],
    );
  }
}
