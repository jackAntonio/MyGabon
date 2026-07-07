import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/app_scaffold.dart';

/// Modération des signalements (ReportUserDialog) — réservé aux
/// administrateurs, RLS l'impose aussi côté serveur.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  final Set<String> _processing = {};

  static const _reasonLabels = {
    'suspicious_behavior': 'Comportement suspect',
    'scam': 'Tentative d\'arnaque',
    'offensive_content': 'Contenu offensant',
    'fake_profile': 'Faux profil',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final reports = await SupabaseService().getFraudReports();
    if (!mounted) return;
    setState(() {
      _reports = reports;
      _loading = false;
    });
  }

  Future<void> _verify(String reportId) async {
    if (_processing.contains(reportId)) return;
    setState(() => _processing.add(reportId));

    final success = await SupabaseService().verifyFraudReport(reportId);

    if (!mounted) return;
    setState(() => _processing.remove(reportId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Signalement vérifié' : 'Erreur'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
    if (success) _load();
  }

  Future<void> _block(String userId) async {
    if (_processing.contains(userId)) return;

    final reason = await _askBlockReason();
    if (reason == null) return; // annulé

    setState(() => _processing.add(userId));
    final success = await SupabaseService().setUserBlocked(
      userId: userId,
      blocked: true,
      reason: reason,
    );

    if (!mounted) return;
    setState(() => _processing.remove(userId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Utilisateur bloqué' : 'Erreur'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<String?> _askBlockReason() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquer cet utilisateur ?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Motif du blocage'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Bloquer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Signalements')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Aucun signalement pour le moment',
                          style: TextStyle(color: AppColors.grey600),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      return _buildReportCard(context, _reports[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    final id = report['id'] as String;
    final suspiciousUserId = report['suspicious_user_id'] as String;
    final reporter = report['reporter'] as Map<String, dynamic>?;
    final suspiciousUser = report['suspicious_user'] as Map<String, dynamic>?;
    final verified = report['verified'] as bool? ?? false;
    final busy = _processing.contains(id) || _processing.contains(suspiciousUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: verified ? AppColors.success : AppColors.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Signalé : ${suspiciousUser?['full_name'] ?? suspiciousUserId}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (verified)
                const Icon(Icons.verified, color: AppColors.success, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text('Par : ${reporter?['full_name'] ?? report['reporter_id']}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            _reasonLabels[report['reason']] ?? report['reason'] as String,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(report['description'] as String,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy || verified ? null : () => _verify(id),
                  child: const Text('Vérifier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: busy ? null : () => _block(suspiciousUserId),
                  icon: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.block, color: AppColors.white),
                  label: const Text('Bloquer'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
