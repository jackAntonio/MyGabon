import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/image_upload_service.dart';

/// Widget pour sélectionner et afficher des images
class ImagePickerWidget extends StatefulWidget {
  final Function(List<String>) onImagesSelected;
  final int maxImages;
  final String productId;
  final String title;

  const ImagePickerWidget({
    super.key,
    required this.onImagesSelected,
    required this.productId,
    this.maxImages = 5,
    this.title = 'Photos du produit',
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final List<String> _selectedImageUrls = [];
  final List<XFile> _selectedImageFiles = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Grille d'images
        if (_selectedImageUrls.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImageUrls.length + 1,
            itemBuilder: (context, index) {
              if (index < _selectedImageUrls.length) {
                return _buildImageTile(_selectedImageUrls[index], index);
              }
              // Bouton ajouter image
              if (_selectedImageUrls.length < widget.maxImages) {
                return _buildAddImageButton();
              }
              return const SizedBox.shrink();
            },
          )
        else
          _buildEmptyState(),

        const SizedBox(height: 16),

        // Bouton Upload (si images sélectionnées)
        if (_selectedImageFiles.isNotEmpty && _selectedImageUrls.isEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadImages,
              icon: _isUploading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.white,
                  ),
                ),
              )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _isUploading
                    ? 'Upload en cours... (${_selectedImageFiles.length})'
                    : 'Uploader ${_selectedImageFiles.length} image(s)',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _showImageSourceMenu,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.grey300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 12),
            Text(
              'Ajouter des photos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Appuyez pour ajouter jusqu\'à ${widget.maxImages} images',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(String imageUrl, int index) {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.grey200,
                child: const Icon(Icons.broken_image, color: AppColors.grey400),
              );
            },
          ),
        ),

        // Bouton supprimer
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ),
        ),

        // Badge "Principal" pour première image
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Principal',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceMenu,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.grey300,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Ajouter',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sélectionner source',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Caméra',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromCamera();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final images = await imageUploadService.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImageFiles.addAll(images);
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final image = await imageUploadService.pickImageFromCamera();
    if (image != null) {
      setState(() {
        _selectedImageFiles.add(image);
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImageFiles.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final urls = await imageUploadService.uploadMultipleImages(
        imageFiles: _selectedImageFiles,
        productId: widget.productId,
      );

      setState(() {
        _selectedImageUrls.addAll(urls);
        _selectedImageFiles.clear();
        _isUploading = false;
      });

      widget.onImagesSelected(_selectedImageUrls);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${urls.length} image(s) uploadée(s) avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImageUrls.removeAt(index);
    });
    widget.onImagesSelected(_selectedImageUrls);
  }
}
