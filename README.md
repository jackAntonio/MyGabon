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

## 🔐 Security & Anti-Fraud Features

GabonConnect includes a comprehensive security, verification, and anti-fraud system:

### User Verification

- **Phone Number Verification**:
  - OTP (One-Time Password) verification via SMS
  - 6-digit codes with 5-minute expiry
  - Max 5 attempts per OTP
  - Integration ready with SMS services (Twilio, AWS SNS)

- **ID Verification**:
  - Optional ID document verification (Passport, National ID, Driver License)
  - Verified user badges on profiles
  - Encrypted ID number storage

### Trust & Reputation System

- **User Ratings & Reviews**:
  - 5-star rating system
  - Detailed review comments (10-500 characters)
  - Review tags (professional, friendly, reliable, etc.)
  - Recommendation percentage tracking
  - Top-rated user lists
  - Automatic review spam cleanup (180+ days)

- **Verified Badges**:
  - Phone-verified badge (checkmark icon)
  - ID-verified badge  
  - Visual trust indicators on user profiles and listings

### Fraud Detection & Prevention

- **Transaction Risk Analysis**:
  - Real-time fraud risk scoring (Safe, Low, Moderate, High, Critical)
  - Analyzes: account age, transaction amount anomalies, frequency, suspicious keywords
  - Automatic flagging of high-risk transactions
  - User risk flags and warnings

- **Suspicious Activity Reporting**:
  - Report suspicious users/listings with evidence
  - Multiple report types: scam attempts, offensive content, fake profiles
  - Automatic user flagging with 3+ reports
  - User blocking capability

- **Anti-Spam & Validation**:
  - SQL injection prevention through input sanitization
  - API rate limiting (10 requests/minute configurable)
  - Secure password hashing (SHA256)
  - Email and phone validation

### Payment Security

- **Escrow System**:
  - Payment hold until transaction completion
  - Three states: Pending → Held → Released
  - Dispute management for contested transactions
  - Automatic refund capability

- **Encryption & Secure Tokens**:
  - Sensitive data encryption (passwords, IDs, payment info)
  - JWT-like secure token generation
  - Phone number masking for display
  - Partial ID number masking

### Security Widgets

- `VerificationBadge` - Display verified status
- `TrustScoreWidget` - Show rating and review count
- `SafetyWarningBanner` - Display fraud risk levels with flags
- `ReportUserDialog` - Easy reporting interface
- `ReviewCard` - Display reviews with moderation options
- `EscrowPaymentCard` - Show escrow transaction status

### Services

1. **VerificationService**:
   - Phone OTP verification flow
   - ID verification management
   - Cleanup of expired verifications

2. **ReviewService**:
   - Manage user reviews and ratings
   - Calculate rating summaries
   - Flag inappropriate reviews
   - Review statistics and analytics

3. **FraudDetectionService**:
   - Analyze transactions for fraud risk
   - Report suspicious activity
   - Block or flag suspicious users
   - Track fraud statistics

### Usage Examples

```dart
// Send OTP for phone verification
final verifyProvider = context.read<VerificationProvider>();
await verifyProvider.sendPhoneOTP('+241612345678');

// Verify OTP
final verified = await verifyProvider.verifyPhoneOTP(phoneNumber, otpCode);

// Submit a review
final reviewProvider = context.read<ReviewProvider>();
await reviewProvider.submitReview(
  reviewerId: currentUserId,
  revieweeId: targetUserId,
  rating: 5,
  comment: 'Excellent service, very professional!',
  tags: ['professional', 'friendly'],
  recommendsUser: true,
);

// Analyze transaction for fraud
final fraudProvider = context.read<FraudDetectionProvider>();
await fraudProvider.analyzeTransaction(
  userId: currentUserId,
  transactionType: 'service_booking',
  amount: 50000,
  recipientId: providerId,
  metadata: {
    'accountAge': 30,
    'previousAverageAmount': 10000,
    'transactionFrequency': 2,
    'description': 'Plumbing repair service',
  },
);

// Report suspicious user
await fraudProvider.reportSuspiciousActivity(
  reporterId: currentUserId,
  suspiciousUserId: suspiciousUserId,
  reason: 'scam_attempt',
  description: 'User requested payment via Bitcoin instead of escrow',
  listingId: listingId,
);

// Display verification badge
VerificationBadge(
  verification: userVerification,
  showLabel: true,
)

// Show fraud warning
SafetyWarningBanner(
  riskLevel: fraudProvider.currentRiskLevel,
  riskFlags: fraudProvider.userRiskFlags,
)
```

### Database Models

- `UserVerification` - Phone & ID verification status
- `UserReview` - Individual review with rating and tags
- `UserRatingSummary` - Aggregated rating statistics
- `FraudReport` - Reported suspicious activity
- `PaymentEscrow` - Payment hold and release tracking
- `BlockedUser` - User block list

### Configuration

All security parameters are customizable:
- OTP validity period (default 5 minutes)
- Max OTP attempts (default 5)
- Rate limiting (default 10 requests/minute)
- Cache expiration periods
## Getting Started1. **VerificationService**:
   - Phone OTP verification flow
   - ID verification management
   - Cleanup of expired verifications

2. **ReviewService**:
   - Manage user reviews and ratings
   - Calculate rating summaries
   - Flag inappropriate reviews
   - Review statistics and analytics

3. **FraudDetectionService**:
   - Analyze transactions for fraud risk
   - Report suspicious activity
   - Block or flag suspicious users
   - Track fraud statistics

### Usage Examples

```dart
// Send OTP for phone verification
final verifyProvider = context.read<VerificationProvider>();
await verifyProvider.sendPhoneOTP('+241612345678');

// Verify OTP
final verified = await verifyProvider.verifyPhoneOTP(phoneNumber, otpCode);

// Submit a review
final reviewProvider = context.read<ReviewProvider>();
await reviewProvider.submitReview(
  reviewerId: currentUserId,
  revieweeId: targetUserId,
  rating: 5,
  comment: 'Excellent service, very professional!',
  tags: ['professional', 'friendly'],
  recommendsUser: true,
);

// Analyze transaction for fraud
final fraudProvider = context.read<FraudDetectionProvider>();
await fraudProvider.analyzeTransaction(
  userId: currentUserId,
  transactionType: 'service_booking',
  amount: 50000,
  recipientId: providerId,
  metadata: {
    'accountAge': 30,
    'previousAverageAmount': 10000,
    'transactionFrequency': 2,
    'description': 'Plumbing repair service',
  },
);

// Report suspicious user
await fraudProvider.reportSuspiciousActivity(
  reporterId: currentUserId,
  suspiciousUserId: suspiciousUserId,
  reason: 'scam_attempt',
  description: 'User requested payment via Bitcoin instead of escrow',
  listingId: listingId,
);

// Display verification badge
VerificationBadge(
  verification: userVerification,
  showLabel: true,
)

// Show fraud warning
SafetyWarningBanner(
  riskLevel: fraudProvider.currentRiskLevel,
  riskFlags: fraudProvider.userRiskFlags,
)
```

### Database Models

- `UserVerification` - Phone & ID verification status
- `UserReview` - Individual review with rating and tags
- `UserRatingSummary` - Aggregated rating statistics
- `FraudReport` - Reported suspicious activity
- `PaymentEscrow` - Payment hold and release tracking
- `BlockedUser` - User block list

### Configuration

All security parameters are customizable:
- OTP validity period (default 5 minutes)
- Max OTP attempts (default 5)
- Rate limiting (default 10 requests/minute)
- Cache expiration periods
- Fraud risk scoring weights



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
