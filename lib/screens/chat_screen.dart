import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../widgets/chat_bubble.dart';

/// Chat screen UI only: list of conversations and a sample chat.
class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  static final List<ChatModel> _conversations = [
    ChatModel(name: 'Jean', lastMessage: 'Are you available?', timestamp: '10:20'),
    ChatModel(name: 'Marie', lastMessage: 'Thanks for the info', timestamp: '09:15'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final convo = _conversations[index];
                return ListTile(
                  title: Text(convo.name),
                  subtitle: Text(convo.lastMessage),
                  trailing: Text(convo.timestamp),
                  onTap: () {
                    // navigate to detailed chat
                  },
                );
              },
            ),
          ),
          const Divider(),
          // sample chat bubble area placeholder
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: const [
                ChatBubble(
                  isMe: false,
                  text: 'Hello there!',
                ),
                ChatBubble(
                  isMe: true,
                  text: 'Hi, how can I help you?',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
