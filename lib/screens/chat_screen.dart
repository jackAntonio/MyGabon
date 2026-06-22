import 'package:flutter/material.dart';
import '../widgets/chat_bubble.dart';
import 'chat_detail_screen.dart';

/// Chat screen UI only: list of conversations and a sample chat.
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: provider.conversations.length,
              itemBuilder: (context, index) {
                final convo = provider.conversations[index];
                return ListTile(
                  title: Text(convo.name),
                  subtitle: Text(convo.lastMessage),
                  trailing: Text(convo.timestamp),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChatDetailScreen()),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          // sample chat bubble area placeholder
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
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
