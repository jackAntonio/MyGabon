import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/chat_model.dart';
import '../services/supabase_service.dart';
import '../widgets/chat_bubble.dart';

/// Fil de conversation avec un interlocuteur donné, avec envoi de message
/// et réception en temps réel (Supabase Realtime) des messages entrants.
class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatDetailScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _service = SupabaseService();
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _service.streamIncomingMessages(widget.otherUserId).listen((rows) {
      if (!mounted) return;
      setState(() {
        for (final row in rows) {
          final message = ChatMessage.fromJson(row);
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
          }
        }
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
    });
  }

  Future<void> _loadHistory() async {
    final rows = await _service.getMessages(widget.otherUserId);
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(rows.map(ChatMessage.fromJson));
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final userId = _service.currentUser?.id;
    if (userId == null) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: userId,
        receiverId: widget.otherUserId,
        content: text,
        read: false,
        createdAt: DateTime.now(),
      ));
    });

    final success = await _service.sendMessage(
      receiverId: widget.otherUserId,
      content: text,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message non envoyé, vérifiez votre connexion'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = _service.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: AppColors.white, fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Démarrez la conversation',
                          style: TextStyle(color: AppColors.grey600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return ChatBubble(
                            isMe: msg.senderId == myId,
                            text: msg.content,
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      filled: true,
                      fillColor: AppColors.grey100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: AppColors.white, size: 18),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
