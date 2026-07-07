import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../utils/validators.dart';
import '../widgets/app_scaffold.dart';
import 'driver_dashboard_screen.dart';

/// Candidature pour devenir livreur MyGabon (soumise à étude de dossier).
class BecomeDriverScreen extends StatefulWidget {
  const BecomeDriverScreen({super.key});

  @override
  State<BecomeDriverScreen> createState() => _BecomeDriverScreenState();
}

class _BecomeDriverScreenState extends State<BecomeDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _phoneController = TextEditingController();
  late final TextEditingController _zoneController = TextEditingController();
  String _vehicleType = 'moto';
  bool _isSubmitting = false;
  bool _loading = true;
  Map<String, dynamic>? _application;

  static const _vehicleTypes = {
    'moto': 'Moto',
    'voiture': 'Voiture',
    'velo': 'Vélo',
    'a_pied': 'À pied',
  };

  @override
  void initState() {
    super.initState();
    _loadExistingApplication();
  }

  Future<void> _loadExistingApplication() async {
    final application = await SupabaseService().getMyDriverApplication();
    if (!mounted) return;
    setState(() {
      _application = application;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final success = await SupabaseService().submitDriverApplication(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        vehicleType: _vehicleType,
        zone: _zoneController.text.trim().isEmpty ? null : _zoneController.text.trim(),
      );

      if (!success) throw Exception('Échec de la soumission');

      await _loadExistingApplication();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Candidature envoyée, en cours d\'examen'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Devenir livreur')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _application != null
              ? _buildStatus(context, _application!)
              : _buildForm(context),
    );
  }

  Widget _buildStatus(BuildContext context, Map<String, dynamic> application) {
    final status = application['status'] as String;

    final (icon, color, title, message) = switch (status) {
      'approved' => (
          Icons.verified,
          AppColors.success,
          'Candidature approuvée !',
          'Vous pouvez accéder à votre tableau de bord livreur.',
        ),
      'rejected' => (
          Icons.cancel_outlined,
          AppColors.error,
          'Candidature refusée',
          (application['rejection_reason'] as String?) ??
              'Votre candidature n\'a pas été retenue.',
        ),
      _ => (
          Icons.hourglass_top,
          AppColors.warning,
          'Candidature en cours d\'examen',
          'Nous étudions votre dossier, vous serez notifié de la décision.',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: 24),
            if (status == 'approved')
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
                  );
                },
                child: const Text('Accéder au tableau de bord'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Livrer pour MyGabon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Devenir livreur n\'est pas ouvert à tout le monde : chaque candidature est examinée. Vous recevez 50% des frais de livraison sur chaque course effectuée.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom complet'),
              validator: Validators.validateNotEmpty,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              decoration: const InputDecoration(labelText: 'Moyen de transport'),
              items: _vehicleTypes.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _vehicleType = value ?? 'moto'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zoneController,
              decoration: const InputDecoration(
                labelText: 'Zone de livraison (optionnel)',
                hintText: 'Ex : Libreville - Akanda',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Envoyer ma candidature'),
            ),
          ],
        ),
      ),
    );
  }
}
