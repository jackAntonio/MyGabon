import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../services/payment_service.dart';

/// Écran pour publier une annonce (produit) sur le marché MyGabon.
class PostAnnouncementScreen extends StatefulWidget {
  const PostAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<PostAnnouncementScreen> createState() => _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState extends State<PostAnnouncementScreen> {
  late final TextEditingController _titleController = TextEditingController();
  late final TextEditingController _descriptionController = TextEditingController();
  late final TextEditingController _priceController = TextEditingController();

  String _selectedCategory = 'Électronique';
  String _selectedCondition = 'Neuf';
  String _selectedLocation = 'Libreville';
  int _quantity = 1;
  bool _isSubmitting = false;

  static const _categories = [
    'Électronique',
    'Mode',
    'Maison & Jardin',
    'Véhicules',
    'Immobilier',
    'Meubles',
    'Autres',
  ];
  static const _conditions = ['Neuf', 'Bon état', 'Occasion'];
  static const _gabonCities = [
    'Libreville',
    'Port-Gentil',
    'Franceville',
    'Oyem',
    'Lambaréné',
    'Mouila',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poster une annonce'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormSection(
                context,
                title: 'Titre du produit',
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Ex : iPhone 14 Pro 256 Go',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  maxLength: 100,
                ),
              ),
              _buildFormSection(
                context,
                title: 'Description',
                child: TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText:
                        'Décrivez votre produit en détail (état, caractéristiques, défauts)',
                    prefixIcon: Icon(Icons.description_rounded),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
              ),
              _buildFormSection(
                context,
                title: 'Catégorie',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value ?? _categories.first),
                ),
              ),
              _buildFormSection(
                context,
                title: 'État du produit',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCondition,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.inventory_2_rounded),
                  ),
                  items: _conditions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCondition = value ?? 'Neuf'),
                ),
              ),
              _buildFormSection(
                context,
                title: 'Prix (FCFA)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        hintText: 'Ex : 150000',
                        prefixIcon: Icon(Icons.payments_rounded),
                        suffixText: 'FCFA',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (double.tryParse(_priceController.text) != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Si payé via MyGabon Wallet : vous recevrez '
                        '${PaymentService.calculateFees(double.parse(_priceController.text)).netToSeller.toStringAsFixed(0)} FCFA '
                        '(commission plateforme 5%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildFormSection(
                context,
                title: 'Quantité',
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed:
                          _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _quantity.toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              _buildFormSection(
                context,
                title: 'Localisation',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLocation,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  items: _gabonCities
                      .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedLocation = value ?? 'Libreville'),
                ),
              ),
              _buildFormSection(
                context,
                title: 'Photo',
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: AppColors.grey500, size: 28),
                        SizedBox(height: 8),
                        Text('Ajout de photo bientôt disponible',
                            style: TextStyle(color: AppColors.grey500)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitListing,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSubmitting ? 'Publication...' : 'Publier l\'annonce',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Future<void> _submitListing() async {
    final price = double.tryParse(_priceController.text);
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs avec un prix valide'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final productId = await SupabaseService().createProduct(
        title: _titleController.text,
        description: _descriptionController.text,
        price: price,
        category: _selectedCategory,
        condition: _selectedCondition,
        location: _selectedLocation,
        quantity: _quantity,
      );

      if (productId == null) {
        throw Exception('La publication a échoué');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce publiée avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );

      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      setState(() {
        _quantity = 1;
        _selectedCategory = _categories.first;
        _selectedCondition = _conditions.first;
        _selectedLocation = _gabonCities.first;
      });
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
}
