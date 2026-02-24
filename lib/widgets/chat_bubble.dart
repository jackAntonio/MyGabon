import 'package:flutter/material.dart';

/// Simple chat bubble for UI-only chat screen.
class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;

  const ChatBubble({Key? key, required this.isMe, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? Colors.green[200] : Colors.grey[200];

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text),
      ),
    );
  }
}
