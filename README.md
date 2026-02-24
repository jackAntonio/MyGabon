# GabonConnect

A modern Flutter super-app for Gabonese users to find services, post announcements,
and buy/sell locally. This repository contains a clean codebase scaffolded for
future Firebase integration and scalability.

## Features

- 💻 Material 3 based clean UI
- 📱 Bottom navigation bar for easy access
- 🎯 Five primary screens: Home, Services, Marketplace, Chat, Profile
- 🧩 Reusable widgets and well-organised folders
- 🔧 Dummy data used; Firebase-ready architecture
- 📝 Commented code suitable for quick onboarding

## Structure

```
lib/
  main.dart
  screens/
    home_screen.dart
    services_screen.dart
    post_announcement_screen.dart
    marketplace_screen.dart
    chat_screen.dart
    profile_screen.dart
  widgets/
    category_grid.dart
    service_card.dart
    product_card.dart
    chat_bubble.dart
    primary_button.dart
  models/
    service_model.dart
    product_model.dart
    chat_model.dart
    user_model.dart
  services/
    dummy_data.dart
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
