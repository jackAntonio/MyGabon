import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/monetization_models.dart';
import '../providers/monetization_provider.dart';
import '../screens/subscription_screen.dart';
import '../screens/analytics_screen.dart';
import '../utils/colors.dart';

/// Monetization profile section widget
class MonetizationProfileSection extends StatelessWidget {
  final String userId;
  
  const MonetizationProfileSection({
    Key? key,
    required this.userId,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubscriptionSection(context),
          SizedBox(height: 16),
          _buildRevenueSection(context),
          SizedBox(height: 16),
          _buildFeatureBoostSection(context),
          SizedBox(height: 16),
          _buildQuickActions(context),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionSection(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        final sub = provider.currentSubscription;
        
        if (sub == null) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Améliorez votre expérience',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Soyez parmi les vendeurs de premier plan avec un abonnement professionnel',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubscriptionScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text('Voir les plans'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Abonnement actif',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          sub.currentTier.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.verified, color: Colors.green, size: 28),
                  ],
                ),
                SizedBox(height: 12),
                
                Text(
                  'Annonces en vedette: ${sub.featuredListingsUsed} / ${sub.currentTier == SubscriptionTier.professional ? '5' : (sub.currentTier == SubscriptionTier.enterprise ? '∞' : '0')}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionScreen(),
                        ),
                      );
                    },
                    child: Text('Gérer l\'abonnement'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRevenueSection(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, provider, _) {
        final revenue = provider.revenueSummary;
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnalyticsScreen()),
            );
          },
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vos revenus',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.trending_up, color: Colors.green, size: 20),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  if (revenue != null) ...[
                    Text(
                      'Revenu net',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${revenue.netEarnings.toStringAsFixed(0)} CFA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions: ${revenue.totalTransactions}',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          'Moy: ${revenue.averageTransactionValue.toStringAsFixed(0)} CFA',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      'Aucun revenu pour le moment',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Voir les détails →',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFeatureBoostSection(BuildContext context) {
    return Consumer<FeaturedListingProvider>(
      builder: (context, provider, _) {
        final featured = provider.userFeaturedListings;
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Annonces en vedette',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                
                if (featured.isEmpty)
                  Text(
                    'Aucune annonce en vedette',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  )
                else
                  ...featured.take(3).map((listing) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.listingId,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Expire dans ${listing.daysRemaining} jours',
                            style: TextStyle(
                              fontSize: 10,
                              color: listing.daysRemaining <= 3
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                
                if (featured.length > 3)
                  Text(
                    '+${featured.length - 3} autres',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildActionCard(
              context,
              icon: Icons.star,
              title: 'Abonnement',
              color: Colors.amber,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubscriptionScreen()),
                );
              },
            ),
            _buildActionCard(
              context,
              icon: Icons.analytics,
              title: 'Analyse',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnalyticsScreen()),
                );
              },
            ),
            _buildActionCard(
              context,
              icon: Icons.star,
              title: 'Mettre en vedette',
              color: Colors.orange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sélectionner une annonce pour la mettre en vedette'),
                  ),
                );
              },
            ),
            _buildActionCard(
              context,
              icon: Icons.receipt,
              title: 'Factures',
              color: Colors.purple,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Historique des transactions')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home screen featured listings section
class FeaturedListingsSection extends StatelessWidget {
  const FeaturedListingsSection({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<FeaturedListingProvider>(
      builder: (context, provider, _) {
        if (provider.userFeaturedListings.isEmpty) {
          return SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'En vedette',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Featured listings will be displayed here with FeaturedBadge widget
          ],
        );
      },
    );
  }
}

/// Revenue banner for home screen
class RevenueInfoBanner extends StatelessWidget {
  const RevenueInfoBanner({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionProvider, PaymentProvider>(
      builder: (context, subProvider, paymentProvider, _) {
        final sub = subProvider.currentSubscription;
        final revenue = paymentProvider.revenueSummary;
        
        if (sub == null) {
          return SizedBox.shrink();
        }
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vous gagnez',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${revenue?.netEarnings.toStringAsFixed(0) ?? '0'} CFA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Plan',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        sub.currentTier.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AnalyticsScreen()),
                  );
                },
                child: Text(
                  'Voir l\'analyse complète →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
