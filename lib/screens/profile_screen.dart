import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/monetization_profile_section.dart';
import 'admin_driver_applications_screen.dart';
import 'become_driver_screen.dart';
import 'driver_dashboard_screen.dart';
import 'edit_profile_screen.dart';
import 'wallet_topup_screen.dart';

/// Profil utilisateur : informations, portefeuille MyGabon, transactions,
/// paramètres.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double? _walletBalance;
  List<Map<String, dynamic>> _transactions = [];
  bool _loadingWallet = true;
  bool _isAdmin = false;
  Map<String, dynamic>? _driverApplication;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _loadRoles();
  }

  Future<void> _loadWalletData() async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return;

    final balance = await SupabaseService().getWalletBalance(userId);
    final transactions = await SupabaseService().getUserTransactions(userId);

    if (!mounted) return;
    setState(() {
      _walletBalance = balance;
      _transactions = List<Map<String, dynamic>>.from(transactions);
      _loadingWallet = false;
    });
  }

  Future<void> _openWalletTopUp() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletTopUpScreen()),
    );
    _loadWalletData();
  }

  Future<void> _loadRoles() async {
    final isAdmin = await SupabaseService().isAdmin();
    final application = await SupabaseService().getMyDriverApplication();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _driverApplication = application;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final fullName = auth.displayName;
    final phoneNumber = auth.profile?['phone_number'] as String? ?? '';

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWalletData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête profil
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.darkBg],
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        phoneNumber,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(
                              initialFullName: fullName,
                              initialPhoneNumber: phoneNumber,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier le profil'),
                    ),
                  ],
                ),
              ),

              // Portefeuille
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Portefeuille MyGabon',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success.withValues(alpha: 0.15),
                            AppColors.accent.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Solde disponible',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.grey600,
                                  )),
                          const SizedBox(height: 8),
                          Text(
                            _loadingWallet
                                ? '...'
                                : '${_walletBalance?.toStringAsFixed(0) ?? 0} FCFA',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openWalletTopUp,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Recharger via Airtel Money'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Historique des transactions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Historique des transactions',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _loadingWallet
                    ? const Center(child: CircularProgressIndicator())
                    : _transactions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  const Icon(Icons.history,
                                      size: 40, color: AppColors.grey400),
                                  const SizedBox(height: 12),
                                  Text('Aucune transaction pour le moment',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppColors.grey600)),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: _transactions
                                .map((t) => _buildTransactionTile(context, t))
                                .toList(),
                          ),
              ),

              // Espace vendeur : abonnement Pro, mise en avant, revenus
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Espace vendeur',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              if (SupabaseService().currentUser?.id != null)
                MonetizationProfileSection(
                  userId: SupabaseService().currentUser!.id,
                ),

              // Administration (réservé aux admins)
              if (_isAdmin)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Administration',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      _buildSettingsTile(
                        context,
                        icon: Icons.local_shipping_outlined,
                        title: 'Candidatures livreur',
                        subtitle: 'Étudier les demandes en attente',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AdminDriverApplicationsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

              // Espace livreur
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Espace livreur',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _buildDriverTile(context),
                  ],
                ),
              ),

              // Paramètres
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paramètres',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _buildSettingsTile(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Gérer vos préférences',
                      onTap: () => _showComingSoon(context, 'Notifications'),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.help_outline,
                      title: 'Aide & Support',
                      subtitle: 'Contactez-nous',
                      onTap: () => _showComingSoon(context, 'Aide & Support'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmLogout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('Se déconnecter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Map<String, dynamic> t) {
    final isSale = t['payment_method'] == null
        ? false
        : SupabaseService().currentUser?.id == t['seller_id'];
    final grossAmount = (t['gross_amount'] as num?)?.toDouble() ?? 0;
    final visibleFee = (t['visible_fee'] as num?)?.toDouble() ?? 0;
    final netToSeller = (t['net_to_seller'] as num?)?.toDouble() ?? grossAmount;
    // Vente : le vendeur reçoit le net après commission (5%), pas le prix affiché.
    // Achat : l'acheteur a payé le prix + frais de service (5%).
    final amount = isSale ? netToSeller : grossAmount + visibleFee;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSale ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSale ? Icons.arrow_downward : Icons.arrow_upward,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isSale ? 'Vente (net après commission)' : 'Achat',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  (t['status'] as String?) ?? 'pending',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.grey600),
                ),
              ],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSale ? AppColors.success : AppColors.error,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverTile(BuildContext context) {
    final status = _driverApplication?['status'] as String?;

    final (title, subtitle, icon, color) = switch (status) {
      'approved' => (
          'Tableau de bord livreur',
          'Voir les livraisons disponibles et vos gains',
          Icons.local_shipping,
          AppColors.success,
        ),
      'pending' => (
          'Candidature en cours d\'examen',
          'Vous serez notifié de la décision',
          Icons.hourglass_top,
          AppColors.warning,
        ),
      'rejected' => (
          'Candidature refusée',
          'Voir le détail',
          Icons.cancel_outlined,
          AppColors.error,
        ),
      _ => (
          'Devenir livreur',
          '50% des frais sur chaque livraison, sous réserve d\'étude de dossier',
          Icons.local_shipping_outlined,
          AppColors.primary,
        ),
    };

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => status == 'approved'
                ? const DriverDashboardScreen()
                : const BecomeDriverScreen(),
          ),
        ).then((_) => _loadRoles());
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.grey600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.grey600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — bientôt disponible')),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
            'Vous devrez vous reconnecter pour accéder à votre compte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: const Text('Se déconnecter',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
