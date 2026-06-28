import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/monetization_models.dart';
import '../providers/monetization_provider.dart';
import '../widgets/monetization_widgets.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = SupabaseService().currentUser?.id ?? '';
    _loadSubscription();
  }

  void _loadSubscription() {
    Future.microtask(() {
      context.read<SubscriptionProvider>().loadSubscription(_userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans d\'abonnement'),
        elevation: 0,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (provider.hasActiveSubscription)
                  _buildCurrentSubscriptionInfo(provider),
                const SizedBox(height: 24),
                const Text(
                  'Plans disponibles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...ProfessionalPlan.allPlans().map((plan) {
                  final isCurrent =
                      provider.currentSubscription?.currentTier == plan.tier;
                  return SubscriptionPlanCard(
                    plan: plan,
                    isCurrentPlan: isCurrent,
                    onUpgrade: isCurrent
                        ? null
                        : () => _upgradeSubscription(context, plan),
                  );
                }),
                const SizedBox(height: 24),
                _buildFAQ(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exploitez le potentiel de votre annonce',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Obtenez l\'accès à des outils d\'annonces premium et augmentez vos revenus',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionInfo(SubscriptionProvider provider) {
    final sub = provider.currentSubscription;
    if (sub == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Abonnement actif',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Plan', sub.currentTier.name),
          _buildInfoRow('Statut', sub.isActive ? 'Actif' : 'Expiré'),
          _buildInfoRow(
            'Renouvellement',
            _formatDate(sub.renewalDate),
          ),
          if (sub.currentTier != SubscriptionTier.free)
            _buildInfoRow(
              'Annonces en vedette utilisées',
              '${sub.featuredListingsUsed} / ${_getMaxFeaturedListings(sub.currentTier)}',
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCancelConfirmation(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Annuler l\'abonnement',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questions fréquemment posées',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          'Puis-je annuler à tout moment?',
          'Oui, vous pouvez annuler votre abonnement à tout moment. Vous aurez accès jusqu\'à la fin de votre période de facturation.',
        ),
        _buildFAQItem(
          'Qu\'est-ce qui est inclus dans chaque plan?',
          'Chaque plan inclut un certain nombre d\'annonces en vedette par mois. Le plan Entreprise offre un accès illimité.',
        ),
        _buildFAQItem(
          'Comment fonctionnent les annonces en vedette?',
          'Les annonces en vedette sont affichées en haut des résultats de recherche et reçoivent 5x plus de vues que les annonces normales.',
        ),
        _buildFAQItem(
          'Y a-t-il une période de test gratuite?',
          'Le forfait gratuit est toujours disponible avec des fonctionnalités de base. Mettez à niveau quand vous êtes prêt.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _upgradeSubscription(
    BuildContext context,
    ProfessionalPlan plan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Améliorer vers ${plan.name}'),
        content: Text(
          'Cela coûtera ${plan.monthlyPrice.toStringAsFixed(0)} CFA par mois.\n\nVoulez-vous continuer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<SubscriptionProvider>();
      await provider.createSubscription(_userId, plan.tier);

      if (mounted && provider.currentSubscription != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abonnement mis à jour avec succès!')),
        );
      }
    }
  }

  Future<void> _showCancelConfirmation(
    BuildContext context,
    SubscriptionProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'abonnement'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler votre abonnement? Vous perdrez accès aux fonctionnalités premium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Garder l\'abonnement'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Annuler l\'abonnement'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await provider.cancelSubscription(_userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abonnement annulé')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMaxFeaturedListings(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return '0';
      case SubscriptionTier.professional:
        return '5';
      case SubscriptionTier.enterprise:
        return '∞';
    }
  }
}
