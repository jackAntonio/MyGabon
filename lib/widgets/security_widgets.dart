import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/security_models.dart';
import '../providers/fraud_detection_provider.dart';
import '../utils/colors.dart';

/// Verification badge widget
class VerificationBadge extends StatelessWidget {
  final UserVerification? verification;
  final bool showLabel;
  final double size;

  const VerificationBadge({
    Key? key,
    required this.verification,
    this.showLabel = true,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (verification == null || !verification!.phoneVerified) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified,
          color: AppColors.accent,
          size: size,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          const Text(
            'Vérifié',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Trust score display widget
class TrustScoreWidget extends StatelessWidget {
  final UserRatingSummary? ratingSummary;
  final bool compact;

  const TrustScoreWidget({
    Key? key,
    required this.ratingSummary,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ratingSummary == null) {
      return Text(
        'Pas encore évalué',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              ratingSummary!.averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: compact ? 12 : 14,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${ratingSummary!.totalReviews} avis)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: compact ? 10 : 12,
              ),
            ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          Text(
            '${ratingSummary!.getRecommendPercentage().toStringAsFixed(0)}% le recommandent',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ],
    );
  }
}

/// Safety warning banner
class SafetyWarningBanner extends StatelessWidget {
  final FraudRiskLevel riskLevel;
  final List<String> riskFlags;
  final VoidCallback? onDismiss;

  const SafetyWarningBanner({
    Key? key,
    required this.riskLevel,
    required this.riskFlags,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (riskLevel == FraudRiskLevel.safe && riskFlags.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = _getRiskColor();
    final icon = _getRiskIcon();
    final text = _getRiskText();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(Icons.close, color: color, size: 18),
                ),
            ],
          ),
          if (riskFlags.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...riskFlags.map((flag) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 28),
                      Expanded(
                        child: Text(
                          '• $flag',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Color _getRiskColor() {
    switch (riskLevel) {
      case FraudRiskLevel.safe:
        return Colors.green;
      case FraudRiskLevel.low:
        return Colors.lightGreen;
      case FraudRiskLevel.moderate:
        return Colors.orange;
      case FraudRiskLevel.high:
        return Colors.deepOrange;
      case FraudRiskLevel.critical:
        return Colors.red;
    }
  }

  IconData _getRiskIcon() {
    switch (riskLevel) {
      case FraudRiskLevel.safe:
        return Icons.verified_user;
      case FraudRiskLevel.low:
        return Icons.info;
      case FraudRiskLevel.moderate:
        return Icons.warning;
      case FraudRiskLevel.high:
        return Icons.warning;
      case FraudRiskLevel.critical:
        return Icons.error;
    }
  }

  String _getRiskText() {
    switch (riskLevel) {
      case FraudRiskLevel.safe:
        return 'Transaction sûre';
      case FraudRiskLevel.low:
        return 'Risque faible détecté';
      case FraudRiskLevel.moderate:
        return 'Risque modéré - Vérifiez les détails';
      case FraudRiskLevel.high:
        return 'Risque élevé - Soyez prudent';
      case FraudRiskLevel.critical:
        return 'Alerte de sécurité critique';
    }
  }
}

/// Report user dialog
class ReportUserDialog extends StatefulWidget {
  final String suspiciousUserId;
  final VoidCallback? onSubmitted;

  const ReportUserDialog({
    Key? key,
    required this.suspiciousUserId,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  late TextEditingController _descriptionController;
  String _selectedReason = 'suspicious_behavior';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Signaler un utilisateur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Reason dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              items: const [
                DropdownMenuItem(
                  value: 'suspicious_behavior',
                  child: Text('Comportement suspect'),
                ),
                DropdownMenuItem(
                  value: 'scam',
                  child: Text('Tentative d\'arnaque'),
                ),
                DropdownMenuItem(
                  value: 'offensive_content',
                  child: Text('Contenu offensant'),
                ),
                DropdownMenuItem(
                  value: 'fake_profile',
                  child: Text('Faux profil'),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedReason = value!);
              },
              decoration: InputDecoration(
                labelText: 'Motif du signalement',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Détails',
                hintText: 'Décrivez pourquoi vous signalez cet utilisateur',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Signaler'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez fournir des détails')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get current user ID from auth provider
      // For now, using placeholder
      final fraudProvider = context.read<FraudDetectionProvider>();

      await fraudProvider.reportSuspiciousActivity(
        reporterId: 'current_user_id', // Replace with actual user ID
        suspiciousUserId: widget.suspiciousUserId,
        reason: _selectedReason,
        description: _descriptionController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signalement envoyé avec succès')),
        );
        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du signalement')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

/// Review card widget
class ReviewCard extends StatelessWidget {
  final UserReview review;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const ReviewCard({
    Key? key,
    required this.review,
    this.onDelete,
    this.onReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Comment
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Tags
            if (review.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: review.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    labelStyle: const TextStyle(fontSize: 11),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  );
                }).toList(),
              ),

            if (review.tags.isNotEmpty) const SizedBox(height: 8),

            // Recommend badge
            if (review.recommendsUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.green, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.thumb_up, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Recommandé',
                      style: TextStyle(color: Colors.green, fontSize: 11),
                    ),
                  ],
                ),
              ),

            // Actions
            if (onDelete != null || onReport != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReport != null)
                    TextButton.icon(
                      onPressed: onReport,
                      icon: const Icon(Icons.flag, size: 16),
                      label: const Text('Signaler'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Escrow payment status card
class EscrowPaymentCard extends StatelessWidget {
  final PaymentEscrow escrow;
  final VoidCallback? onRelease;
  final VoidCallback? onDispute;

  const EscrowPaymentCard({
    Key? key,
    required this.escrow,
    this.onRelease,
    this.onDispute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Paiement en fiducie',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),

            // Amount
            Text(
              '${escrow.amount.toStringAsFixed(2)} CFA',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Info
            _buildInfoRow('Service', escrow.serviceId),
            _buildInfoRow('ID Transaction', escrow.transactionId),
            _buildInfoRow('Statut', _getStatusText()),

            const SizedBox(height: 12),

            // Actions
            if (escrow.status == EscrowStatus.held) ...[
              Row(
                children: [
                  if (onRelease != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onRelease,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Libérer'),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (onDispute != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onDispute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Contester'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (escrow.status) {
      case EscrowStatus.pending:
        return 'En attente';
      case EscrowStatus.held:
        return 'Gelé';
      case EscrowStatus.released:
        return 'Libéré';
      case EscrowStatus.refunded:
        return 'Remboursé';
      case EscrowStatus.disputed:
        return 'Contesté';
    }
  }

  Color _getStatusColor() {
    switch (escrow.status) {
      case EscrowStatus.pending:
        return Colors.grey;
      case EscrowStatus.held:
        return Colors.orange;
      case EscrowStatus.released:
        return Colors.green;
      case EscrowStatus.refunded:
        return Colors.blue;
      case EscrowStatus.disputed:
        return Colors.red;
    }
  }
}
