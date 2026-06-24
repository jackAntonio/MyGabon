import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

/// Widget displaying connection status and offline indicator
/// Shows connection quality and sync status
class ConnectionStatusBanner extends StatelessWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onSyncPressed;

  const ConnectionStatusBanner({
    Key? key,
    this.backgroundColor,
    this.textColor,
    this.onSyncPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnlineMode) {
          // Optionally hide banner when online (remove return to show always)
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: backgroundColor ?? Colors.red[700],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectivity.connectionStatusText,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: textColor ?? Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      connectivity.isConnected
                          ? 'Les données en attente seront synchronisées'
                          : 'Mode hors ligne - Les actions seront en file d\'attente',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: (textColor ?? Colors.white)
                                .withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
              if (connectivity.isConnected && onSyncPressed != null)
                TextButton(
                  onPressed: onSyncPressed,
                  child: Text(
                    'Sync',
                    style: TextStyle(color: textColor ?? Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget showing detailed connection quality information
class ConnectionQualityIndicator extends StatelessWidget {
  final bool showLabel;

  const ConnectionQualityIndicator({
    Key? key,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        Color indicatorColor;
        IconData icon;

        switch (connectivity.connectionQuality) {
          case ConnectionQuality.offline:
            indicatorColor = Colors.red;
            icon = Icons.signal_cellular_off;
            break;
          case ConnectionQuality.poor:
            indicatorColor = Colors.orange;
            icon = Icons.phonelink_lock;
            break;
          case ConnectionQuality.moderate:
            indicatorColor = Colors.amber;
            icon = Icons.portable_wifi_off;
            break;
          case ConnectionQuality.good:
            indicatorColor = Colors.green;
            icon = Icons.signal_cellular_4_bar;
            break;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: indicatorColor,
              size: 16,
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                connectivity.connectionStatusText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: indicatorColor,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Sync status widget showing offline queue progress
class SyncStatusWidget extends StatelessWidget {
  final void Function()? onTap;

  const SyncStatusWidget({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnlineMode) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vous êtes hors ligne',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Vos actions seront synchronisées dès que possible',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.orange[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange[700]!,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Optimized list loading widget with pagination
class OptimizedListLoader extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Future<void> Function()? onLoadMore;
  final bool isLoading;
  final bool hasReachedEnd;
  final ScrollController? controller;

  const OptimizedListLoader({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.onLoadMore,
    this.isLoading = false,
    this.hasReachedEnd = false,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        return ListView.builder(
          cacheExtent: connectivity.connectionQuality == ConnectionQuality.poor
              ? 100 // Reduced cache extent for poor connections
              : 500,
          controller: controller, // Normal cache extent
          itemCount: itemCount + (isLoading ? 1 : 0) + (!hasReachedEnd ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at end for pagination
            if (index == itemCount && !hasReachedEnd) {
              // Trigger load more
              if (onLoadMore != null && !isLoading) {
                Future.microtask(() => onLoadMore!());
              }
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              );
            }

            if (index >= itemCount) {
              return const SizedBox.shrink();
            }

            return itemBuilder(context, index);
          },
        );
      },
    );
  }
}
