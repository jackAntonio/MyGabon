# GabonConnect

A modern Flutter super-app for Gabonese users to find services, post announcements,
and buy/sell locally. This repository contains a clean codebase scaffolded for
future Firebase integration and scalability.

## Features

- 💻 Material 3 based clean UI
- � Login/register UI ready for Firebase Authentication
- 📱 Bottom navigation bar with five tabs: Home, Services, Post, Marketplace, Profile
- 🎯 Screens for home, services, post announcement, marketplace, chat and profile
- 🧠 State management using Provider with auth/service/marketplace/chat providers
- 🧩 Reusable widgets and well-organised folders with models, providers, services, utils
- 🌍 Geolocation and notifications service placeholders
- 🔧 Dummy data used; Firebase-ready architecture
- 📝 Commented code suitable for quick onboarding

## Structure

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

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. Clone this repo:
   ```bash
   git clone <repo-url> GabonConnect
   cd GabonConnect
   ```
3. Get packages:
   ```bash
   flutter pub get
   ```
4. Run on a simulator or device:
   ```bash
   flutter run
   ```

## Notes

- Firebase dependencies are already listed in `pubspec.yaml` but commented out.
  Uncomment and configure as needed.
- UI is responsive but further testing on different screen sizes is recommended.
- This template is prepared for additional features and back-end integration.

---

Happy coding! 🎉
