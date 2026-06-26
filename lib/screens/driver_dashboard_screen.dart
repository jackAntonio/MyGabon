import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';

/// Tableau de bord livreur : livraisons disponibles à réclamer et livraisons
/// en cours à marquer comme effectuées (50% des frais de livraison crédités
/// au moment de la livraison).
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  List<Map<String, dynamic>> _available = [];
  List<Map<String, dynamic>> _mine = [];
  bool _loading = true;
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final available = await SupabaseService().getAvailableDeliveries();
    final mine = await SupabaseService().getMyDeliveries();
    if (!mounted) return;
    setState(() {
      _available = available;
      _mine = mine;
      _loading = false;
    });
  }

  Future<void> _claim(String transactionId) async {
    if (_processing.contains(transactionId)) return;
    setState(() => _processing.add(transactionId));
    final success = await SupabaseService().claimDelivery(transactionId);
    if (!mounted) return;
    setState(() => _processing.remove(transactionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Livraison réclamée'
            : 'Cette livraison n\'est plus disponible'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
    if (success) _load();
  }

  Future<void> _complete(String transactionId) async {
    if (_processing.contains(transactionId)) return;
    setState(() => _processing.add(transactionId));
    final success = await SupabaseService().completeDelivery(transactionId);
    if (!mounted) return;
    setState(() => _processing.remove(transactionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Livraison marquée comme effectuée' : 'Erreur'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
    if (success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes livraisons'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Disponibles'),
            Tab(text: 'En cours'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(
                  _available,
                  emptyText: 'Aucune livraison disponible pour le moment',
                  buildAction: (t) {
                    final id = t['id'] as String;
                    final busy = _processing.contains(id);
                    return ElevatedButton(
                      onPressed: busy ? null : () => _claim(id),
                      child: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Réclamer'),
                    );
                  },
                ),
                _buildList(
                  _mine,
                  emptyText: 'Aucune livraison en cours',
                  buildAction: (t) {
                    final id = t['id'] as String;
                    final busy = _processing.contains(id);
                    return ElevatedButton(
                      onPressed: busy ? null : () => _complete(id),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                      child: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Marquer livrée'),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> deliveries, {
    required String emptyText,
    required Widget Function(Map<String, dynamic>) buildAction,
  }) {
    if (deliveries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(emptyText,
                  style: const TextStyle(color: AppColors.grey600)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final t = deliveries[index];
          final deliveryFee = (t['delivery_fee'] as num).toDouble();
          final payout = deliveryFee * 0.5;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Frais de livraison : ${deliveryFee.toStringAsFixed(0)} FCFA',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Votre gain : ${payout.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: buildAction(t)),
              ],
            ),
          );
        },
      ),
    );
  }
}
