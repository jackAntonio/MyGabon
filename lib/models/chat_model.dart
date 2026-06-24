/// Un message échangé entre deux utilisateurs.
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool read;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.read,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['sender_id'] as String,
        receiverId: json['receiver_id'] as String,
        content: json['content'] as String,
        read: json['read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Aperçu d'une conversation avec un interlocuteur (pour la liste des chats).
class Conversation {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime lastTimestamp;

  Conversation({
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastTimestamp,
  });
}
