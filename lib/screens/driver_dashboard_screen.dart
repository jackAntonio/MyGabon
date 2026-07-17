import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/app_scaffold.dart';

/// Tableau de bord livreur : livraisons disponibles à réclamer et livraisons
/// en cours à clôturer (50% des frais de livraison crédités à la livraison).
///
/// Deux clôtures distinctes selon le mode de paiement : une commande déjà
/// réglée se marque simplement livrée, tandis qu'une commande en paiement à
/// la livraison doit être encaissée — c'est cette confirmation-là qui crédite
/// le vendeur et qui inscrit les espèces au débit du livreur (recette à
/// remettre à MyGabon, plafonnée par l'encours autorisé).
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  List<Map<String, dynamic>> _available = [];
  List<Map<String, dynamic>> _mine = [];
  ({double owed, double limit, double remaining})? _cash;
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
    final cash = await SupabaseService().getMyDriverCashSummary();
    if (!mounted) return;
    setState(() {
      _available = available;
      _mine = mine;
      _cash = cash;
      _loading = false;
    });
  }

  static bool _isCod(Map<String, dynamic> t) =>
      t['payment_method'] == 'cash_on_delivery';

  /// Ce que le livreur encaisse à la remise : exactement le "Total à payer"
  /// affiché à l'acheteur à la commande.
  static double _amountToCollect(Map<String, dynamic> t) =>
      ((t['gross_amount'] as num?)?.toDouble() ?? 0) +
      ((t['visible_fee'] as num?)?.toDouble() ?? 0) +
      ((t['delivery_fee'] as num?)?.toDouble() ?? 0);

  /// Enveloppe commune : le serveur renvoie des motifs de refus explicites
  /// (plafond d'encours, livraison déjà prise, propre vente...), on les
  /// affiche tels quels plutôt qu'un « Erreur » générique.
  Future<void> _run(
    String transactionId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_processing.contains(transactionId)) return;
    setState(() => _processing.add(transactionId));
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
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
      if (mounted) setState(() => _processing.remove(transactionId));
    }
  }

  Future<void> _claim(String transactionId) => _run(
        transactionId,
        () => SupabaseService().claimDelivery(transactionId),
        'Livraison réclamée',
      );

  Future<void> _complete(String transactionId) => _run(
        transactionId,
        () => SupabaseService().completeDelivery(transactionId),
        'Livraison marquée comme effectuée',
      );

  /// Encaissement : confirmation explicite exigée, car ce geste crédite le
  /// vendeur et rend le livreur redevable de la somme envers MyGabon —
  /// confirmer sans avoir l'argent en main, c'est le devoir quand même.
  Future<void> _confirmCash(Map<String, dynamic> t) async {
    final id = t['id'] as String;
    final amount = _amountToCollect(t);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer l\'encaissement'),
        content: Text(
          'Confirmez-vous avoir reçu ${amount.toStringAsFixed(0)} FCFA en espèces ?\n\n'
          'Le vendeur sera crédité immédiatement et cette somme sera inscrite '
          'à votre recette à remettre à MyGabon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('J\'ai encaissé'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _run(
      id,
      () => SupabaseService().confirmCashOnDelivery(id),
      'Paiement encaissé, vendeur crédité',
    );
  }

  /// Sortie de secours quand l'acheteur ne règle pas : sans elle la livraison
  /// resterait bloquée en « en cours » indéfiniment.
  Future<void> _reportRefused(Map<String, dynamic> t) async {
    final id = t['id'] as String;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paiement refusé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La commande sera annulée et l\'article rapporté au vendeur.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motif (facultatif)',
                hintText: 'Acheteur absent, refus de payer...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true) return;

    await _run(
      id,
      () => SupabaseService().reportCashOnDeliveryRefused(
        id,
        reason: reason.isEmpty ? null : reason,
      ),
      'Refus signalé, commande annulée',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
          : Column(
              children: [
                if (_cash != null && _cash!.owed > 0) _buildCashBanner(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(
                        _available,
                        emptyText: 'Aucune livraison disponible pour le moment',
                        buildActions: (t) => [
                          ElevatedButton(
                            onPressed: _processing.contains(t['id'])
                                ? null
                                : () => _claim(t['id'] as String),
                            child: _processing.contains(t['id'])
                                ? const _ButtonSpinner()
                                : const Text('Réclamer'),
                          ),
                        ],
                      ),
                      _buildList(
                        _mine,
                        emptyText: 'Aucune livraison en cours',
                        buildActions: (t) => _isCod(t)
                            ? [
                                ElevatedButton(
                                  onPressed: _processing.contains(t['id'])
                                      ? null
                                      : () => _confirmCash(t),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success),
                                  child: _processing.contains(t['id'])
                                      ? const _ButtonSpinner()
                                      : Text(
                                          'Encaisser ${_amountToCollect(t).toStringAsFixed(0)} FCFA',
                                        ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _processing.contains(t['id'])
                                      ? null
                                      : () => _reportRefused(t),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side:
                                        const BorderSide(color: AppColors.error),
                                  ),
                                  child: const Text('Paiement refusé'),
                                ),
                              ]
                            : [
                                ElevatedButton(
                                  onPressed: _processing.contains(t['id'])
                                      ? null
                                      : () => _complete(t['id'] as String),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success),
                                  child: _processing.contains(t['id'])
                                      ? const _ButtonSpinner()
                                      : const Text('Marquer livrée'),
                                ),
                              ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Encours d'espèces : le livreur doit savoir en permanence ce qu'il porte
  /// et ce qui lui reste avant que le plafond ne lui bloque les prochaines
  /// courses en paiement à la livraison.
  Widget _buildCashBanner(BuildContext context) {
    final cash = _cash!;
    final atLimit = cash.remaining <= 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (atLimit ? AppColors.error : AppColors.warning)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (atLimit ? AppColors.error : AppColors.warning)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 18, color: atLimit ? AppColors.error : AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Recette à remettre : ${cash.owed.toStringAsFixed(0)} FCFA',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: atLimit ? AppColors.error : AppColors.grey900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            atLimit
                ? 'Plafond atteint : remettez votre recette à MyGabon pour reprendre des livraisons à encaisser.'
                : 'Encore ${cash.remaining.toStringAsFixed(0)} FCFA encaissables avant le plafond de ${cash.limit.toStringAsFixed(0)} FCFA.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> deliveries, {
    required String emptyText,
    required List<Widget> Function(Map<String, dynamic>) buildActions,
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
          final isCod = _isCod(t);

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
                if (isCod) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'À ENCAISSER : ${_amountToCollect(t).toStringAsFixed(0)} FCFA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey900,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
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
                for (final action in buildActions(t))
                  SizedBox(width: double.infinity, child: action),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
    );
  }
}
