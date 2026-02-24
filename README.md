# GabonConnect

A premium, modern Flutter super-app for Gabonese users to find services, post announcements,
and buy/sell locally. Designed with a professional UI comparable to Uber or Bolt, featuring
smooth animations, dark mode support, and a scalable architecture ready for Firebase integration.

## 🎨 Design Features

- **Premium UI**: Inspired by Gabon's national colors (Deep Emerald Green, Warm Yellow, Ocean Blue)
- **🌙 Dark Mode**: Full light and dark theme support with system theme detection
- **✨ Micro-interactions**: Smooth page transitions, fade-in animations, loading shimmer effects
- **🎯 Floating Navigation**: Modern bottom navigation bar with elegant elevation and rounded corners
- **📱 Responsive Layout**: Optimized for all screen sizes
- **🎨 Material 3**: Modern Material design with premium spacing and shadows

## ✨ Features

- 🔐 Login/Register UI ready for Firebase Authentication
- 📱 Bottom navigation with 5 main tabs + floating design
- 🏠 Home screen with greeting, search, categories, featured providers
- 🔧 Services screen with search/filter and skeleton loaders
- ➕ Post announcement form with validation
- 🛒 Marketplace with grid layout and product cards
- 💬 Chat module with conversation list and chat bubbles
- 👤 Profile screen with user info and logout
- 🧠 State management using Provider
- 🌍 Geolocation and notifications service placeholders
- 🔧 Dummy data with simulated loading states
- 📝 Well-commented, production-ready code

## 🎨 Color Palette (Gabon-Inspired)

- **Primary**: Deep Emerald Green (#0B6E4F)
- **Secondary**: Warm Yellow (#F4C430)
- **Accent**: Ocean Blue (#0077B6)
- **Background**: Soft Light Grey (#F7F9FA)
- **Text**: Dark Charcoal (#1E1E1E)

## 🌍 Low-Bandwidth Optimization (African Regions)

GabonConnect is optimized for low-speed and unstable internet connections:

### Core Optimizations

- **📡 Connectivity Detection**: Real-time network quality monitoring with 4 levels
  - Offline, Poor (<100 KB/s), Moderate (100-500 KB/s), Good (>500 KB/s)

- **💾 Local Caching (Hive)**: 
  - Cache-first strategy: load from cache instantly, sync in background
  - Automatic cache expiration (24h for services/products, 7d for user data)
  - Offline access to previously loaded data

- **📊 Pagination & Lazy Loading**:
  - Load 20 items per page (adjustable based on bandwidth)
  - Load next page only on demand
  - Reduced list cache extent on poor connections

- **🖼️ Image Optimization**:
  - Progressive loading: placeholder → low-res → full-res
  - Automatic compression based on bandwidth (50% on poor, 75% moderate, 100% good)
  - Caching with `cached_network_image`

- **📤 Offline Queue & Auto-Sync**:
  - Queue user actions when offline (post service, send message, etc.)
  - Automatic sync with exponential backoff when connection returns
  - Shows pending action count and sync progress

- **📉 Data Usage Reduction**:
  - Send/receive only essential fields
  - Batch requests to reduce API calls
  - Skip non-critical data (metadata, images on poor connections)

- **⚡ UI Optimization**:
  - Disable heavy animations on poor connections
  - Adaptive list rendering (reduced cache extent)
  - Connection status banner showing real-time status

### Usage Example

```dart
// Automatically adapts to network quality
OptimizedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  connectivityService: connectivityService,
  width: 300,
  height: 200,
  // On poor: 50% resolution, 50% quality
  // On moderate: 75% resolution, 65% quality
  // On good: 100% resolution, 75% quality
);

// Listen to connection changes
context.watch<ConnectivityService>().addListener(() {
  if (connected) {
    // Auto-sync pending actions
    context.read<OfflineQueueService>().syncAllPendingActions();
  }
});
```

### Services Included

1. **ConnectivityService** - Network quality monitoring
2. **CacheService** - Hive-based local storage with TTL
3. **OfflineQueueService** - Queue & auto-sync offline actions  
4. **ImageCompressionService** - Bandwidth-aware image scaling

### Configuration

All optimization parameters are customizable. See `lib/utils/optimization_patterns.dart` for detailed patterns.



```
lib/
  main.dart
  models/
    service_model.dart
    product_model.dart
    chat_model.dart
    user_model.dart
  screens/
    home_screen.dart
    services_screen.dart
    post_announcement_screen.dart
    marketplace_screen.dart
    chat_screen.dart
    profile_screen.dart
    login_screen.dart
    register_screen.dart
  widgets/
    category_grid.dart
    category_icon.dart
    service_card.dart
    product_card.dart
    chat_bubble.dart
    custom_button.dart
    custom_textfield.dart
    primary_button.dart
  providers/
    auth_provider.dart
    service_provider.dart
    marketplace_provider.dart
    chat_provider.dart
  services/
    dummy_data.dart
    geolocation_service.dart
    notification_service.dart
  utils/
    validators.dart
    theme.dart
```

## Getting Started

1. **Install Flutter SDK**:
   https://flutter.dev/docs/get-started/install

2. **Clone the repository**:
   ```bash
   git clone https://github.com/jackAntonio/MyGabon.git
   cd MyGabon
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## 🔌 Firebase Integration

Firebase dependencies are listed in `pubspec.yaml` but commented out. To enable:

1. Uncomment Firebase packages in `pubspec.yaml`
2. Run `flutter pub get`
3. Configure Firebase for your project
4. Implement backend logic in service and auth providers

## 📝 Development Notes

- All screens are responsive and tested on various screen sizes
- Skeleton loaders simulate network delays (1-second fake delay)
- Theme automatically adapts to system brightness preference
- All widgets follow Material 3 design principles
- Code is well-commented for easy team onboarding

## 🎯 Next Steps

1. Implement Firebase Authentication
2. Connect to real backend APIs
3. Add real geolocation functionality
4. Implement FCM for push notifications
5. Add image upload and storage
6. Expand with more screens/features

---

**Happy coding!** 🎉
Built with ❤️ for Gabonese users.
