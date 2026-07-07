import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../services/geolocation_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/image_picker_widget.dart';
import 'package:uuid/uuid.dart';

/// Écran pour publier un service (prestation) sur MyGabon.
class PostServiceScreen extends StatefulWidget {
  const PostServiceScreen({super.key});

  @override
  State<PostServiceScreen> createState() => _PostServiceScreenState();
}

class _PostServiceScreenState extends State<PostServiceScreen> {
  late final TextEditingController _titleController = TextEditingController();
  late final TextEditingController _descriptionController = TextEditingController();
  late final TextEditingController _priceController = TextEditingController();

  String _selectedCategory = 'Électricité';
  String _selectedLocation = 'Libreville';
  bool _isSubmitting = false;
  bool _isLocating = false;
  double? _latitude;
  double? _longitude;
  List<String> _imageUrls = [];
  final String _serviceId = const Uuid().v4(); // ID unique pour le service

  static const _categories = [
    'Électricité',
    'Nettoyage',
    'Informatique',
    'Menuiserie',
    'Beauté',
    'Autres',
  ];
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
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Proposer un service'),
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
                title: 'Titre du service',
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Ex : Réparation électroménager à domicile',
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
                        'Décrivez votre prestation (expérience, matériel, zone couverte)',
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
                title: 'Prix (FCFA)',
                child: TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    hintText: 'Ex : 15000',
                    prefixIcon: Icon(Icons.payments_rounded),
                    suffixText: 'FCFA',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              _buildFormSection(
                context,
                title: 'Localisation',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLocation,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                      items: _gabonCities
                          .map((city) =>
                              DropdownMenuItem(value: city, child: Text(city)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedLocation = value ?? 'Libreville'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isLocating ? null : _useCurrentLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _latitude != null
                                  ? Icons.my_location_rounded
                                  : Icons.location_searching_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _latitude != null
                            ? 'Position actuelle enregistrée'
                            : 'Utiliser ma position actuelle (recommandé)',
                      ),
                    ),
                  ],
                ),
              ),
              ImagePickerWidget(
                productId: _serviceId,
                maxImages: 5,
                title: 'Photos du service',
                onImagesSelected: (urls) {
                  setState(() => _imageUrls = urls);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitService,
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
                    _isSubmitting ? 'Publication...' : 'Publier le service',
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

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    final position = await GeolocationService().getCurrentLocation();
    if (!mounted) return;

    setState(() {
      _isLocating = false;
      _latitude = position?.latitude;
      _longitude = position?.longitude;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(position == null
            ? 'Position indisponible : vérifiez que la localisation est activée'
            : 'Position actuelle enregistrée'),
        backgroundColor: position == null ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _submitService() async {
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
      final serviceId = await SupabaseService().createService(
        title: _titleController.text,
        description: _descriptionController.text,
        price: price,
        category: _selectedCategory,
        location: _selectedLocation,
        imageUrl: _imageUrls.isNotEmpty ? _imageUrls.first : null,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (serviceId == null) {
        throw Exception('La publication a échoué');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service publié avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );

      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      setState(() {
        _selectedCategory = _categories.first;
        _selectedLocation = _gabonCities.first;
        _latitude = null;
        _longitude = null;
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
