# 📸 Système d'Upload d'Images MyGabon

Guide complet pour l'upload et la gestion d'images dans l'app.

---

## 🎯 Vue d'ensemble

Le système d'upload d'images permet aux vendeurs de:
- ✅ Sélectionner des images depuis la galerie
- ✅ Prendre des photos avec la caméra
- ✅ Uploader jusqu'à 5 images par produit
- ✅ Organiser les images (principale en premier)
- ✅ Supprimer les images indésirables
- ✅ Afficher les images dans les annonces

---

## 📦 Architecture

### Services

#### `ImageUploadService` (`lib/services/image_upload_service.dart`)

Service singleton pour gérer tout l'upload d'images.

**Méthodes principales:**

```dart
// Sélectionner une image
XFile? image = await imageUploadService.pickImageFromGallery();
XFile? photo = await imageUploadService.pickImageFromCamera();

// Sélectionner plusieurs images
List<XFile> images = await imageUploadService.pickMultipleImages();

// Uploader une image
String? url = await imageUploadService.uploadImage(
  imageFile: xfile,
  productId: 'prod_123',
);

// Uploader plusieurs images
List<String> urls = await imageUploadService.uploadMultipleImages(
  imageFiles: [xfile1, xfile2],
  productId: 'prod_123',
);

// Supprimer une image
bool success = await imageUploadService.deleteImage(imageUrl);
```

### Widgets

#### `ImagePickerWidget` (`lib/widgets/image_picker_widget.dart`)

Widget réutilisable pour sélectionner et afficher des images.

**Propriétés:**

```dart
ImagePickerWidget(
  productId: 'prod_123',           // ID unique du produit
  maxImages: 5,                     // Max images (défaut: 5)
  onImagesSelected: (urls) {        // Callback avec URLs uploadées
    setState(() => _imageUrls = urls);
  },
)
```

**Features:**

- 📸 Grille d'images avec 3 colonnes
- ➕ Bouton pour ajouter des images
- ❌ Bouton pour supprimer chaque image
- 🏷️ Badge "Principal" sur la première image
- 🌐 Affichage des URLs uploadées depuis Supabase
- ⚡ Upload en temps réel avec indicateur de progression

---

## 🗂️ Stockage Supabase

### Bucket Configuration

**Bucket Name:** `product-images`

**Structure des chemins:**

```
product-images/
├── products/
│   ├── prod_123/
│   │   ├── prod_123_uuid1.jpg
│   │   ├── prod_123_uuid2.jpg
│   │   └── prod_123_uuid3.jpg
│   └── prod_456/
│       ├── prod_456_uuid1.jpg
│       └── prod_456_uuid2.jpg
```

### Politique d'accès (RLS)

```sql
-- Allow authenticated users to upload images
CREATE POLICY "Users can upload product images"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'product-images' 
  AND auth.role() = 'authenticated'
);

-- Allow anyone to view images (public)
CREATE POLICY "Product images are public"
ON storage.objects
FOR SELECT
USING (bucket_id = 'product-images');

-- Allow users to delete their own images
CREATE POLICY "Users can delete their product images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'product-images'
  AND owner_id = auth.uid()
);
```

---

## 🚀 Utilisation dans PostAnnouncementScreen

```dart
class _PostAnnouncementScreenState extends State<PostAnnouncementScreen> {
  List<String> _imageUrls = [];
  final String _productId = const Uuid().v4();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poster une annonce')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ... autres champs ...
              
              // Widget d'upload d'images
              ImagePickerWidget(
                productId: _productId,
                maxImages: 5,
                onImagesSelected: (urls) {
                  setState(() => _imageUrls = urls);
                },
              ),
              
              // ... bouton de publication ...
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitListing() async {
    // Soumettre l'annonce avec images
    await SupabaseService().createProduct(
      title: _titleController.text,
      description: _descriptionController.text,
      price: double.parse(_priceController.text),
      category: _selectedCategory,
      condition: _selectedCondition,
      location: _selectedLocation,
      quantity: _quantity,
      imageUrl: _imageUrls.isNotEmpty ? _imageUrls[0] : null,
    );
  }
}
```

---

## 🔐 Sécurité

### ✅ Bonnes pratiques implémentées

| Feature | Status | Description |
|---------|--------|-------------|
| Compression | ✅ | Images compressées avant upload (80% quality) |
| Size check | ⏳ | À implémenter: max 5MB par image |
| Format check | ⏳ | À implémenter: JPG/PNG uniquement |
| User auth | ✅ | Seuls utilisateurs auth peuvent uploader |
| RLS Policies | ⏳ | À configurer dans Supabase |
| CORS | ⏳ | À configurer pour accès public |

### À faire avant production

1. **Configurer RLS Policies** dans Supabase Storage
2. **Limiter la taille** des fichiers (max 5MB)
3. **Valider les formats** (JPG, PNG seulement)
4. **Ajouter antivirus** pour les uploads
5. **Configurer CORS** pour domaine MyGabon

---

## ⚙️ Configuration iOS

### Permissions Info.plist

Ajouter à `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>MyGabon a besoin d'accéder à vos photos</string>

<key>NSCameraUsageDescription</key>
<string>MyGabon a besoin d'accéder à votre caméra</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>MyGabon veut enregistrer vos photos</string>
```

---

## ⚙️ Configuration Android

### Permissions AndroidManifest.xml

Ajouter à `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Build.gradle

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

---

## 🖼️ Affichage d'images dans les annonces

### Dans MarketplaceDetailScreen

```dart
Image.network(
  product.imageUrl ?? 'https://via.placeholder.com/400x400',
  fit: BoxFit.cover,
  width: double.infinity,
  height: 300,
  errorBuilder: (context, error, stackTrace) {
    return Container(
      color: AppColors.grey200,
      child: Icon(Icons.image_not_supported),
    );
  },
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded / 
              loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  },
)
```

---

## 📊 Flux de données

```
PostAnnouncementScreen
        ↓
ImagePickerWidget
        ↓
  [Sélection]
  /    |    \
Galerie Camera Multiple
        ↓
  [Upload]
        ↓
ImageUploadService
        ↓
[Supabase Storage]
        ↓
[URL publique]
        ↓
  [Affichage]
        ↓
MarketplaceDetailScreen
```

---

## 🐛 Troubleshooting

| Problème | Solution |
|----------|----------|
| "Permission denied" | Vérifier Info.plist / AndroidManifest.xml |
| Image pas uploadée | Vérifier connexion internet + permissions Supabase |
| Bucket not found | Créer bucket `product-images` dans Supabase |
| CORS error | Configurer CORS dans Storage settings |
| Image blanche | Augmenter délai loading ou vérifier URL |

---

## 📱 Taille des images

**Recommandations:**

- **Galerie:** 80% quality compression
- **Caméra:** 80% quality compression
- **Max size:** 5MB (à implémenter)
- **Format:** JPG/PNG (à valider)
- **Dimensions:** 800x800px minimum

---

## 🔮 Fonctionnalités futures

- [ ] Cropping/editing des images
- [ ] Filtres et effets
- [ ] Galerie interactive avec zoom
- [ ] Upload par drag & drop (web)
- [ ] Compression automatique
- [ ] Reconnaissance de contenu (modération)
- [ ] Watermark optionnel
- [ ] Lightbox sur annonces

---

## 📚 Ressources

- [image_picker](https://pub.dev/packages/image_picker) - Flutter official package
- [image_cropper](https://pub.dev/packages/image_cropper) - Image cropping
- [Supabase Storage](https://supabase.com/docs/guides/storage) - Official docs
- [Flutter Image](https://flutter.dev/docs/development/ui/assets-and-images) - Flutter images guide

