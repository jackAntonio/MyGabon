/// Service for image optimization and compression
/// Reduces bandwidth usage for image uploads and downloads
class ImageCompressionService {
  /// Maximum allowed image dimensions (width/height)
  static const int maxDimension = 1024;

  /// JPEG compression quality (0-100)
  static const int jpegQuality = 75;

  /// Calculate optimal image size based on bandwidth
  /// Returns a map with 'width' and 'height' keys
  static Map<String, int> getOptimalDimensions(
    int originalWidth,
    int originalHeight,
    int estimatedBandwidthKbps,
  ) {
    // For poor connections, scale down more aggressively
    double scaleFactor = 1.0;

    if (estimatedBandwidthKbps < 100) {
      // Poor bandwidth: use 50% of original
      scaleFactor = 0.5;
    } else if (estimatedBandwidthKbps < 500) {
      // Moderate bandwidth: use 75% of original
      scaleFactor = 0.75;
    }

    int targetWidth = (originalWidth * scaleFactor).toInt();
    int targetHeight = (originalHeight * scaleFactor).toInt();

    // Ensure we don't exceed max dimensions
    if (targetWidth > maxDimension || targetHeight > maxDimension) {
      final maxRatio = maxDimension /
          (targetWidth > targetHeight ? targetWidth : targetHeight);
      targetWidth = (targetWidth * maxRatio).toInt();
      targetHeight = (targetHeight * maxRatio).toInt();
    }

    return {'width': targetWidth, 'height': targetHeight};
  }

  /// Get low-res placeholder for progress image loading
  /// Returns a tiny, highly compressed version for quick display
  static String getPlaceholderUrl(String imageUrl) {
    // Generate placeholder with progressive loading
    // In real implementation, use image service that provides multiple sizes
    return '$imageUrl?w=50&h=50&q=10';
  }

  /// Get mobile-optimized image URL
  /// Adapts image size based on device constraints
  static String getMobileOptimizedUrl(
    String imageUrl, {
    required int width,
    required int height,
  }) {
    // Ensure URL format supports image optimization
    // This assumes backend supports image resizing (e.g., via Cloudinary)

    if (!imageUrl.contains('?')) {
      return '$imageUrl?w=$width&h=$height&q=$jpegQuality';
    } else {
      return '$imageUrl&w=$width&h=$height&q=$jpegQuality';
    }
  }

  /// Estimate file size of compressed image
  /// Returns estimated size in KB
  static double estimateCompressedSize(
    int width,
    int height,
    int quality,
  ) {
    // Rough estimation: width * height * quality factor / compression ratio
    // Typical JPEG compression ratio is ~10:1
    const bytesPerPixel = 3; // RGB
    final pixels = width * height;
    final qualityFactor = quality / 100.0;
    final estimatedBytes = (pixels * bytesPerPixel * qualityFactor) / 10;

    return estimatedBytes / 1024; // Convert to KB
  }

  /// Get image loading strategy based on bandwidth
  /// Returns recommended number of images to load simultaneously
  static int getMaxConcurrentImageLoads(int estimatedBandwidthKbps) {
    if (estimatedBandwidthKbps < 100) return 1; // Poor: load 1 at a time
    if (estimatedBandwidthKbps < 500) return 2; // Moderate: load 2 at a time
    return 4; // Good: load 4 at a time
  }

  /// Get progressive image loading delay
  /// Delay between loading consecutive images
  static Duration getImageLoadingDelay(int estimatedBandwidthKbps) {
    if (estimatedBandwidthKbps < 100) {
      return const Duration(milliseconds: 500); // Poor: wait longer
    } else if (estimatedBandwidthKbps < 500) {
      return const Duration(milliseconds: 200); // Moderate: wait a bit
    }
    return Duration.zero; // Good: no delay
  }
}

/// Image optimization hints for UI components
class ImageOptimizationConfig {
  final int targetWidth;
  final int targetHeight;
  final int compressionQuality;
  final Duration loadingDelay;
  final bool showPlaceholder;

  ImageOptimizationConfig({
    required this.targetWidth,
    required this.targetHeight,
    required this.compressionQuality,
    required this.loadingDelay,
    this.showPlaceholder = true,
  });

  /// Create optimized config based on bandwidth
  factory ImageOptimizationConfig.forBandwidth(
    int estimatedBandwidthKbps, {
    int? preferredWidth,
    int? preferredHeight,
  }) {
    final dimensions = ImageCompressionService.getOptimalDimensions(
      preferredWidth ?? 512,
      preferredHeight ?? 512,
      estimatedBandwidthKbps,
    );

    int quality = ImageCompressionService.jpegQuality;
    if (estimatedBandwidthKbps < 100) {
      quality = 50;
    } else if (estimatedBandwidthKbps < 500) quality = 65;

    return ImageOptimizationConfig(
      targetWidth: dimensions['width']!,
      targetHeight: dimensions['height']!,
      compressionQuality: quality,
      loadingDelay: ImageCompressionService.getImageLoadingDelay(
        estimatedBandwidthKbps,
      ),
      showPlaceholder: estimatedBandwidthKbps < 500,
    );
  }
}
