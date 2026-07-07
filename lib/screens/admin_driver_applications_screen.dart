import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/app_scaffold.dart';

/// Étude des candidatures livreur (réservé aux administrateurs, RLS l'impose
/// aussi côté serveur).
class AdminDriverApplicationsScreen extends StatefulWidget {
  const AdminDriverApplicationsScreen({super.key});

  @override
  State<AdminDriverApplicationsScreen> createState() =>
      _AdminDriverApplicationsScreenState();
}

class _AdminDriverApplicationsScreenState
    extends State<AdminDriverApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  final Set<String> _processing = {};

  static const _vehicleLabels = {
    'moto': 'Moto',
    'voiture': 'Voiture',
    'velo': 'Vélo',
    'a_pied': 'À pied',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final applications = await SupabaseService().getPendingDriverApplications();
    if (!mounted) return;
    setState(() {
      _applications = applications;
      _loading = false;
    });
  }

  Future<void> _decide(String applicationId, bool approve) async {
    if (_processing.contains(applicationId)) return;

    String? reason;
    if (!approve) {
      reason = await _askRejectionReason();
      if (reason == null) return; // annulé
    }

    setState(() => _processing.add(applicationId));
    final success = await SupabaseService().reviewDriverApplication(
      applicationId: applicationId,
      approve: approve,
      reason: reason,
    );

    if (!mounted) return;
    setState(() => _processing.remove(applicationId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? (approve ? 'Candidature approuvée' : 'Candidature refusée')
            : 'Erreur lors du traitement'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
    if (success) _load();
  }

  Future<String?> _askRejectionReason() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motif du refus'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Optionnel'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirmer le refus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Candidatures livreur')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _applications.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Aucune candidature en attente',
                          style: TextStyle(color: AppColors.grey600),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _applications.length,
                    itemBuilder: (context, index) {
                      final app = _applications[index];
                      return _buildApplicationCard(context, app);
                    },
                  ),
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, Map<String, dynamic> app) {
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
            app['full_name'] as String,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text('Téléphone : ${app['phone_number']}',
              style: Theme.of(context).textTheme.bodySmall),
          Text(
            'Véhicule : ${_vehicleLabels[app['vehicle_type']] ?? app['vehicle_type']}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if ((app['zone'] as String?)?.isNotEmpty ?? false)
            Text('Zone : ${app['zone']}',
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            final id = app['id'] as String;
            final busy = _processing.contains(id);
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _decide(id, false),
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text('Refuser',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : () => _decide(id, true),
                    icon: busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.check, color: AppColors.white),
                    label: const Text('Approuver'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
