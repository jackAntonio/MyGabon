import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/monetization_models.dart';
import '../providers/monetization_provider.dart';
import '../utils/colors.dart';

/// Subscription plan card
class SubscriptionPlanCard extends StatelessWidget {
  final ProfessionalPlan plan;
  final bool isCurrentPlan;
  final VoidCallback? onUpgrade;
  
  const SubscriptionPlanCard({
    Key? key,
    required this.plan,
    this.isCurrentPlan = false,
    this.onUpgrade,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrentPlan ? 8 : 4,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isCurrentPlan
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      plan.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (isCurrentPlan)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Actuel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            
            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${plan.monthlyPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'CFA/mois',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Benefits
            ...plan.benefits.map((benefit) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )),
            
            SizedBox(height: 16),
            
            // Action button
            if (!isCurrentPlan && onUpgrade != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'S\'abonner maintenant',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Featured listing badge for listings
class FeaturedBadge extends StatelessWidget {
  final FeaturedListing listing;
  final bool compact;
  
  const FeaturedBadge({
    Key? key,
    required this.listing,
    this.compact = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!listing.isActive) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.white, size: compact ? 12 : 14),
          SizedBox(width: 2),
          Text(
            'En vedette',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!compact && listing.daysRemaining <= 3)
            Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                '(${listing.daysRemaining}j)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Boost listing dialog
class BoostListingDialog extends StatefulWidget {
  final String listingId;
  final String userId;
  final VoidCallback? onBoostSuccess;
  
  const BoostListingDialog({
    Key? key,
    required this.listingId,
    required this.userId,
    this.onBoostSuccess,
  }) : super(key: key);
  
  @override
  State<BoostListingDialog> createState() => _BoostListingDialogState();
}

class _BoostListingDialogState extends State<BoostListingDialog> {
  int _selectedDuration = 7;
  bool _isProcessing = false;
  
  @override
  Widget build(BuildContext context) {
    final price7 = 4999.0;
    final price30 = 14999.0;
    final selectedPrice = _selectedDuration == 7 ? price7 : price30;
    
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mettre en vedette votre annonce',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            Text(
              'Augmentez la visibilité et les clics',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            
            // Duration selection
            _buildDurationOption(
              context,
              duration: 7,
              price: price7,
              label: '7 jours',
              description: 'Parfait pour un test',
            ),
            SizedBox(height: 12),
            _buildDurationOption(
              context,
              duration: 30,
              price: price30,
              label: '30 jours',
              description: 'Meilleure valeur (20% économies)',
            ),
            
            SizedBox(height: 20),
            
            // Benefits
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avantages',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildBenefit('Badge "En vedette" visible'),
                  _buildBenefit('Positionné en haut des recherches'),
                  _buildBenefit('5x plus de vues en moyenne'),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Price display
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(fontSize: 14)),
                  Text(
                    '${selectedPrice.toStringAsFixed(0)} CFA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _boostListing(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text('Mettre en vedette'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDurationOption(
    BuildContext context, {
    required int duration,
    required double price,
    required String label,
    required String description,
  }) {
    final isSelected = _selectedDuration == duration;
    
    return InkWell(
      onTap: () => setState(() => _selectedDuration = duration),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            Row(
              children: [
                Radio<int>(
                  value: duration,
                  groupValue: _selectedDuration,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDuration = value);
                    }
                  },
                  activeColor: AppColors.primary,
                ),
                Text(
                  '${price.toStringAsFixed(0)} CFA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenefit(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
  
  Future<void> _boostListing(BuildContext context) async {
    setState(() => _isProcessing = true);
    
    try {
      final provider = context.read<FeaturedListingProvider>();
      final success = await provider.boostListing(
        listingId: widget.listingId,
        userId: widget.userId,
        durationDays: _selectedDuration,
      );
      
      if (mounted) {
        Navigator.pop(context);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Annonce mise en vedette avec succès!')),
          );
          widget.onBoostSuccess?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la mise en vedette')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}

/// Revenue summary card
class RevenueSummaryCard extends StatelessWidget {
  final RevenueSummary? summary;
  
  const RevenueSummaryCard({Key? key, required this.summary}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucune donnée de revenu'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé des revenus',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            _buildRevenueRow(
              'Revenus bruts',
              summary!.totalEarnings,
              Colors.green,
            ),
            _buildRevenueRow(
              'Commissions payées',
              -summary!.platformCommissionsPaid,
              Colors.red,
            ),
            _buildRevenueRow(
              'Frais d\'abonnement',
              -summary!.subscriptionsFeesPaid,
              Colors.red,
            ),
            _buildRevenueRow(
              'Annonces en vedette',
              -summary!.featuredListingsCost,
              Colors.red,
            ),
            
            Divider(height: 16),
            
            _buildRevenueRow(
              'Revenus nets',
              summary!.netEarnings,
              AppColors.primary,
              isBold: true,
            ),
            
            SizedBox(height: 12),
            
            Text(
              'Transactions: ${summary!.totalTransactions}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRevenueRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            '${amount >= 0 ? '+' : ''}${amount.toStringAsFixed(0)} CFA',
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Analytics metrics card
class AnalyticsMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final IconData icon;
  
  const AnalyticsMetricCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    required this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Advertisement banner widget
class AdBanner extends StatelessWidget {
  final Advertisement ad;
  final VoidCallback? onAdClicked;
  
  const AdBanner({
    Key? key,
    required this.ad,
    this.onAdClicked,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!ad.isActive) {
      return SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: onAdClicked,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(ad.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ad.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                ad.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
