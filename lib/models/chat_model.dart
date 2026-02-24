/// Represents a chat conversation or message preview.
class ChatModel {
  final String name;
  final String lastMessage;
  final String timestamp;

  ChatModel({
    required this.name,
    required this.lastMessage,
    required this.timestamp,
  });
}
