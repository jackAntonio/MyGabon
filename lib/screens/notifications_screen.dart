import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/app_scaffold.dart';
import 'chat_detail_screen.dart';
import 'orders_screen.dart';

/// Centre de notifications in-app : historique persisté côté serveur
/// (table `notifications`, écrite par les Edge Functions), pas seulement
/// ce que le tiroir de notifications de l'OS a bien voulu garder.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final notifications = await SupabaseService().getNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _loading = false;
    });
  }

  Future<void> _onTap(Map<String, dynamic> notification) async {
    if (notification['read'] != true) {
      await SupabaseService().markNotificationRead(notification['id'] as String);
      if (mounted) {
        setState(() => notification['read'] = true);
      }
    }

    if (!mounted) return;
    switch (notification['type']) {
      case 'chat_message':
        final data = notification['data'] as Map<String, dynamic>?;
        final senderId = data?['sender_id'] as String?;
        final senderName = data?['sender_name'] as String?;
        if (senderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                otherUserId: senderId,
                otherUserName: senderName ?? 'Conversation',
              ),
            ),
          );
        }
        break;
      case 'delivery_status':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrdersScreen()),
        );
        break;
      // driver_application, report_verified : purement informatives, pas
      // de navigation dédiée pour l'instant.
    }
  }

  static const _typeIcons = {
    'chat_message': Icons.chat_bubble_outline_rounded,
    'delivery_status': Icons.local_shipping_outlined,
    'driver_application': Icons.badge_outlined,
    'report_verified': Icons.shield_outlined,
    'cash_remittance': Icons.account_balance_wallet_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Aucune notification pour le moment',
                          style: TextStyle(color: AppColors.grey600),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.grey200),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final read = notification['read'] == true;
                      return ListTile(
                        tileColor: read ? null : AppColors.primary.withValues(alpha: 0.04),
                        leading: CircleAvatar(
                          backgroundColor:
                              read ? AppColors.grey200 : AppColors.primary,
                          child: Icon(
                            _typeIcons[notification['type']] ??
                                Icons.notifications_outlined,
                            size: 18,
                            color: read ? AppColors.grey600 : AppColors.white,
                          ),
                        ),
                        title: Text(
                          notification['title'] as String,
                          style: TextStyle(
                            fontWeight: read ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          notification['body'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: read
                            ? null
                            : const Icon(Icons.circle, size: 8, color: AppColors.primary),
                        onTap: () => _onTap(notification),
                      );
                    },
                  ),
      ),
    );
  }
}
