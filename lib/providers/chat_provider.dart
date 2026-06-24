import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/supabase_service.dart';

/// Provider de messagerie : liste des conversations + envoi de messages.
/// Le fil d'une conversation ouverte est géré directement par
/// ChatDetailScreen via le flux temps réel de SupabaseService.
class ChatProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Conversation> _conversations = [];
  bool _loading = true;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _loading;

  ChatProvider() {
    loadConversations();
  }

  Future<void> loadConversations() async {
    _loading = true;
    notifyListeners();

    final rawConversations = await _service.getConversations();
    final result = <Conversation>[];

    for (final raw in rawConversations) {
      final otherUserId = raw['other_user_id'] as String;
      final profile = await _service.getPublicProfile(otherUserId);
      result.add(Conversation(
        otherUserId: otherUserId,
        otherUserName: profile?['full_name'] as String? ?? 'Utilisateur',
        otherUserAvatar: profile?['avatar_url'] as String?,
        lastMessage: raw['content'] as String,
        lastTimestamp: DateTime.parse(raw['created_at'] as String),
      ));
    }

    result.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
    _conversations = result;
    _loading = false;
    notifyListeners();
  }

  Future<bool> sendMessage(String otherUserId, String content) {
    return _service.sendMessage(receiverId: otherUserId, content: content);
  }
}
