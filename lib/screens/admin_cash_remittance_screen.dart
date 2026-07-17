import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/app_scaffold.dart';

/// Remise de recette COD (réservé aux administrateurs, RLS + RPC l'imposent
/// aussi côté serveur). Liste les espèces que chaque livreur a encaissées en
/// paiement à la livraison et doit encore remettre à MyGabon ; confirmer une
/// remise libère d'autant le plafond d'encours du livreur.
class AdminCashRemittanceScreen extends StatefulWidget {
  const AdminCashRemittanceScreen({super.key});

  @override
  State<AdminCashRemittanceScreen> createState() =>
      _AdminCashRemittanceScreenState();
}

class _AdminCashRemittanceScreenState extends State<AdminCashRemittanceScreen> {
  List<Map<String, dynamic>> _collections = [];
  bool _loading = true;
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final collections = await SupabaseService().getOutstandingCashCollections();
    if (!mounted) return;
    setState(() {
      _collections = collections;
      _loading = false;
    });
  }

  /// Recettes regroupées par livreur, avec le total dû, pour une lecture
  /// « qui me doit combien » plutôt qu'une liste plate de transactions.
  Map<String, List<Map<String, dynamic>>> get _byDriver {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final c in _collections) {
      (grouped[c['driver_id'] as String] ??= []).add(c);
    }
    return grouped;
  }

  Future<void> _confirm(Map<String, dynamic> collection) async {
    final id = collection['id'] as String;
    final amount = (collection['amount_collected'] as num).toDouble();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la remise'),
        content: Text(
          'Confirmez-vous avoir reçu ${amount.toStringAsFixed(0)} FCFA en espèces '
          'de ce livreur ?\n\nSon plafond d\'encours sera libéré d\'autant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Recette reçue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (_processing.contains(id)) return;
    setState(() => _processing.add(id));
    try {
      await SupabaseService().confirmCashRemittance(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remise confirmée'),
          backgroundColor: AppColors.success,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _byDriver;

    return AppScaffold(
      appBar: AppBar(title: const Text('Recettes à remettre')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _collections.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Aucune recette en attente de remise',
                          style: TextStyle(color: AppColors.grey600),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final entry in groups.entries)
                        _buildDriverGroup(context, entry.value),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDriverGroup(
    BuildContext context,
    List<Map<String, dynamic>> collections,
  ) {
    final driver = collections.first['driver'] as Map<String, dynamic>?;
    final driverName = driver?['full_name'] as String? ?? 'Livreur';
    final total = collections.fold<double>(
      0,
      (sum, c) => sum + (c['amount_collected'] as num).toDouble(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  driverName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} FCFA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          Text(
            '${collections.length} recette(s) à remettre',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.grey600),
          ),
          const Divider(height: 24),
          for (final c in collections) _buildCollectionRow(context, c),
        ],
      ),
    );
  }

  Widget _buildCollectionRow(
    BuildContext context,
    Map<String, dynamic> collection,
  ) {
    final id = collection['id'] as String;
    final amount = (collection['amount_collected'] as num).toDouble();
    final busy = _processing.contains(id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${amount.toStringAsFixed(0)} FCFA',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: busy ? null : () => _confirm(collection),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Recette reçue'),
            ),
          ),
        ],
      ),
    );
  }
}
