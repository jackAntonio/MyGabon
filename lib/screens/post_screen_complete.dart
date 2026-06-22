import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';

/// Complete Post Screen - Create new marketplace listing
class PostScreenComplete extends ConsumerStatefulWidget {
  const PostScreenComplete({Key? key}) : super(key: key);

  @override
  ConsumerState<PostScreenComplete> createState() =>
      _PostScreenCompleteState();
}

class _PostScreenCompleteState extends ConsumerState<PostScreenComplete> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;

  String _selectedCategory = 'Électronique';
  String _selectedCondition = 'Neuf';
  int _quantity = 1;
  bool _isPublished = true;
  bool _isSubmitting = false;

  final categories = [
    'Électronique',
    'Vêtements',
    'Maison',
    'Services',
    'Meubles',
    'Autres',
  ];

  final conditions = ['Neuf', 'Bon état', 'Occasion'];
  final gabonCities = [
    'Libreville',
    'Port-Gentil',
    'Franceville',
    'Oyem',
    'Mouila',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _locationController = TextEditingController(text: gabonCities[0]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
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
              // Title
              _buildFormSection(
                context,
                title: 'Titre du produit',
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Ex: iPhone 14 Pro 256GB',
                    prefixIcon: const Icon(Icons.title_rounded),
                  ),
                  maxLength: 100,
                ),
              ),

              // Description
              _buildFormSection(
                context,
                title: 'Description',
                child: TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText:
                        'Décrivez votre produit en détail (état, caractéristiques, défauts)',
                    prefixIcon: const Icon(Icons.description_rounded),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
              ),

              // Category
              _buildFormSection(
                context,
                title: 'Catégorie',
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category_rounded),
                  ),
                  items: categories
                      .map((category) =>
                          DropdownMenuItem(value: category, child: Text(category)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value ?? 'Électronique'),
                ),
              ),

              // Condition
              _buildFormSection(
                context,
                title: 'État du produit',
                child: DropdownButtonFormField<String>(
                  value: _selectedCondition,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.inventory_2_rounded),
                  ),
                  items: conditions
                      .map((condition) =>
                          DropdownMenuItem(value: condition, child: Text(condition)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCondition = value ?? 'Neuf'),
                ),
              ),

              // Price
              _buildFormSection(
                context,
                title: 'Prix (FCFA)',
                child: TextField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    hintText: 'Ex: 150000',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    suffixText: 'FCFA',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),

              // Quantity
              _buildFormSection(
                context,
                title: 'Quantité',
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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

              // Location
              _buildFormSection(
                context,
                title: 'Localisation',
                child: DropdownButtonFormField<String>(
                  value: _locationController.text,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_rounded),
                  ),
                  items: gabonCities
                      .map((city) =>
                          DropdownMenuItem(value: city, child: Text(city)))
                      .toList(),
                  onChanged: (value) =>
                      _locationController.text = value ?? 'Libreville',
                ),
              ),

              // Publish toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Publier maintenant',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'L\'annonce sera visible pour tous',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey600,
                              ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isPublished,
                      onChanged: (value) =>
                          setState(() => _isPublished = value),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitListing,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _submitListing() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez remplir tous les champs'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final productData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'quantity': _quantity,
        'location': _locationController.text,
        'published': _isPublished,
      };

      // This will trigger the createProductProvider
      // You can use ref.read(createProductProvider) in a real app
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Annonce publiée avec succès!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
