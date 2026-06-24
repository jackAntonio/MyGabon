import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

/// Service d'upload d'images vers Supabase Storage
class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();

  late final SupabaseClient _client;
  final _imagePicker = ImagePicker();
  static const String _bucketName = 'product-images';

  factory ImageUploadService() {
    return _instance;
  }

  ImageUploadService._internal() {
    _client = Supabase.instance.client;
  }

  /// Sélectionner une image depuis la galerie
  Future<XFile?> pickImageFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      debugPrint('❌ Erreur sélection image: $e');
      return null;
    }
  }

  /// Prendre une photo avec la caméra
  Future<XFile?> pickImageFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      debugPrint('❌ Erreur prise de photo: $e');
      return null;
    }
  }

  /// Sélectionner plusieurs images
  Future<List<XFile>> pickMultipleImages() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      return images;
    } catch (e) {
      debugPrint('❌ Erreur sélection images multiples: $e');
      return [];
    }
  }

  /// Uploader une image vers Supabase Storage
  Future<String?> uploadImage({
    required XFile imageFile,
    required String productId,
  }) async {
    try {
      // Lire le fichier
      final bytes = await imageFile.readAsBytes();

      // Générer un nom unique
      final fileName = '${productId}_${const Uuid().v4()}.jpg';
      final filePath = 'products/$productId/$fileName';

      // Uploader vers Supabase Storage
      await _client.storage.from(_bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Retourner l'URL publique
      final publicUrl = _client.storage.from(_bucketName).getPublicUrl(filePath);
      debugPrint('✅ Image uploadée: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Erreur upload image: $e');
      return null;
    }
  }

  /// Uploader plusieurs images
  Future<List<String>> uploadMultipleImages({
    required List<XFile> imageFiles,
    required String productId,
  }) async {
    final uploadedUrls = <String>[];

    for (final imageFile in imageFiles) {
      try {
        final url = await uploadImage(
          imageFile: imageFile,
          productId: productId,
        );
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        debugPrint('❌ Erreur upload image ${imageFile.name}: $e');
      }
    }

    debugPrint('✅ ${uploadedUrls.length}/${imageFiles.length} images uploadées');
    return uploadedUrls;
  }

  /// Supprimer une image
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extraire le chemin depuis l'URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      // Format: /storage/v1/object/public/product-images/products/...
      final filePath = pathSegments.skip(5).join('/');

      await _client.storage.from(_bucketName).remove([filePath]);
      debugPrint('✅ Image supprimée: $filePath');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression image: $e');
      return false;
    }
  }

  /// Obtenir l'URL publique d'une image
  String getPublicUrl(String filePath) {
    return _client.storage.from(_bucketName).getPublicUrl(filePath);
  }

  /// Compresser une image avant upload
  Future<File?> compressImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileSize = await file.length();

      // Si fichier < 2MB, pas de compression nécessaire
      if (fileSize < 2 * 1024 * 1024) {
        return file;
      }

      debugPrint('📦 Compression d\'image (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB)');
      // TODO: Implémenter compression avec un package comme flutter_image_compress
      return file;
    } catch (e) {
      debugPrint('❌ Erreur compression: $e');
      return null;
    }
  }
}

final imageUploadService = ImageUploadService();
