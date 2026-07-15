import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
      // Rejeter tout fichier qui n'est pas une vraie image (magic bytes,
      // pas l'extension : un .jpg renommé ne passe pas)
      final rawBytes = await imageFile.readAsBytes();
      final rawMime = _detectImageMime(rawBytes);
      if (rawMime == null) {
        debugPrint('❌ Upload refusé: le fichier n\'est pas une image valide');
        return null;
      }

      // Compresser si nécessaire avant upload (peut ré-encoder en JPEG)
      final bytes = await _compressIfNeeded(rawBytes);
      final mime = _detectImageMime(bytes) ?? rawMime;
      final extension = _extensionForMime(mime);

      // Générer un nom unique
      final fileName = '${productId}_${const Uuid().v4()}.$extension';
      final filePath = 'products/$productId/$fileName';

      // Uploader vers Supabase Storage
      await _client.storage.from(_bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: mime,
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

  /// Détecte le type MIME réel d'une image via ses magic bytes.
  /// Renvoie null si le contenu n'est ni JPEG, ni PNG, ni WebP.
  String? _detectImageMime(Uint8List bytes) {
    if (bytes.length < 12) return null;
    // JPEG : FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // PNG : 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    // WebP : "RIFF" .... "WEBP"
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  String _extensionForMime(String mime) {
    switch (mime) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }

  /// Compresse les octets d'une image si elle dépasse 2MB (coût de stockage
  /// Supabase). Utilise compressWithList (et non compressWithFile) pour
  /// fonctionner aussi bien sur web (XFile sans vrai chemin disque) que sur
  /// mobile. Renvoie les octets d'origine si la compression échoue plutôt
  /// que de bloquer l'upload.
  Future<Uint8List> _compressIfNeeded(Uint8List bytes) async {
    if (bytes.length < 2 * 1024 * 1024) {
      return bytes;
    }

    debugPrint(
        '📦 Compression d\'image (${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB)');
    try {
      return await FlutterImageCompress.compressWithList(
        bytes,
        quality: 80,
        minWidth: 1600,
        minHeight: 1600,
      );
    } catch (e) {
      debugPrint('⚠️ Compression échouée, upload de l\'image originale: $e');
      return bytes;
    }
  }
}

final imageUploadService = ImageUploadService();
