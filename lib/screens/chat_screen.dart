import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/chat_provider.dart';
import '../widgets/app_scaffold.dart';
import 'chat_detail_screen.dart';

/// Liste des conversations de l'utilisateur.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);

    return AppScaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        onRefresh: provider.loadConversations,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.conversations.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Aucune conversation pour le moment.\nContactez un prestataire ou un vendeur pour commencer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.grey600),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: provider.conversations.length,
                    itemBuilder: (context, index) {
                      final convo = provider.conversations[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          backgroundImage: convo.otherUserAvatar != null
                              ? NetworkImage(convo.otherUserAvatar!)
                              : null,
                          child: convo.otherUserAvatar == null
                              ? Text(
                                  convo.otherUserName.isNotEmpty
                                      ? convo.otherUserName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: AppColors.white),
                                )
                              : null,
                        ),
                        title: Text(convo.otherUserName),
                        subtitle: Text(
                          convo.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatTime(convo.lastTimestamp),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey500),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                otherUserId: convo.otherUserId,
                                otherUserName: convo.otherUserName,
                                otherUserAvatar: convo.otherUserAvatar,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }
}
