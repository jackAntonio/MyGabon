import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/image_compression_service.dart';

/// Optimized network image widget with progressive loading
/// Shows placeholder first, then low-res image, then full-res
class OptimizedNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final ConnectivityService? connectivityService;
  final bool showPlaceholder;
  
  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.connectivityService,
    this.showPlaceholder = true,
  });
  
  @override
  State<OptimizedNetworkImage> createState() => _OptimizedNetworkImageState();
}

class _OptimizedNetworkImageState extends State<OptimizedNetworkImage> {
  late final ImageOptimizationConfig _config;
  
  @override
  void initState() {
    super.initState();
    _config = _initializeConfig();
  }
  
  /// Initialize image optimization config based on bandwidth
  ImageOptimizationConfig _initializeConfig() {
    final bandwidth = widget.connectivityService?.getEstimatedBandwidth() ?? 500;
    return ImageOptimizationConfig.forBandwidth(
      bandwidth,
      preferredWidth: (widget.width ?? 300).toInt(),
      preferredHeight: (widget.height ?? 200).toInt(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }
    
    // Get optimized image URL based on bandwidth
    final optimizedUrl = ImageCompressionService.getMobileOptimizedUrl(
      widget.imageUrl!,
      width: _config.targetWidth,
      height: _config.targetHeight,
    );
    
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          // Placeholder (tiny, highly compressed)
          if (_config.showPlaceholder && widget.showPlaceholder)
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[300],
              child: Icon(Icons.image, color: Colors.grey[600]),
            ),
          
          // Progressive image loading with caching
          CachedNetworkImage(
            imageUrl: optimizedUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            memCacheWidth: _config.targetWidth,
            memCacheHeight: _config.targetHeight,
            // Placeholder while loading
            placeholder: (context, url) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
            // Error state
            errorWidget: (context, url, error) {
              return Container(
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, color: Colors.grey[600]),
              );
            },
            // Cache duration
            cacheManager: null, // Use default cache manager
            fadeInDuration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
  
  /// Build placeholder for missing/empty images
  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius,
      ),
      child: Icon(
        Icons.image,
        color: Colors.grey[600],
        size: 32,
      ),
    );
  }
}

/// Low-bandwidth optimized image loading
/// Loads only when network is good or cached
class BandwidthAwareImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final ConnectivityService connectivityService;
  final BoxFit fit;
  
  const BandwidthAwareImage({
    super.key,
    required this.imageUrl,
    required this.connectivityService,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });
  
  @override
  Widget build(BuildContext context) {
    final connectivity = Provider.of<ConnectivityService>(context);
    return _buildImage(context, connectivity);
  }
  
  Widget _buildImage(BuildContext context, ConnectivityService connectivity) {
    return _BandwidthAwareImageContent(
    connectivity: connectivity,
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
  );
  }
}

class _BandwidthAwareImageContent extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final ConnectivityService connectivity;
  final BoxFit fit;
  
  const _BandwidthAwareImageContent({
    required this.imageUrl,
    required this.connectivity,
    required this.width,
    required this.height,
    required this.fit,
  });
  
  @override
  Widget build(BuildContext context) {
    // Skip auto-loading images on poor connections (user can tap to load)
    if (connectivity.connectionQuality == ConnectionQuality.poor) {
          return GestureDetector(
        onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('👆 Tap pour charger l\'image complète'),
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Tap pour charger',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
    }
    
    // Load image normally on moderate/good connections
    return OptimizedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      connectivityService: connectivity,
    );
  }
}
