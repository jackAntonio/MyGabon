import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Simple chat bubble for UI-only chat screen.
class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;

  const ChatBubble({Key? key, required this.isMe, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color =
        isMe ? AppColors.primary.withValues(alpha: 0.8) : Colors.grey[700];

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.white),
        ),
      ),
    );
  }
}
