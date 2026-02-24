import 'package:flutter/material.dart';
import '../models/chat_model.dart';

/// Chat provider containing conversations and messages skeleton.
class ChatProvider extends ChangeNotifier {
  List<ChatModel> _conversations = [];

  ChatProvider() {
    _conversations = [
      ChatModel(name: 'Jean', lastMessage: 'Are you available?', timestamp: '10:20'),
      ChatModel(name: 'Marie', lastMessage: 'Thanks for the info', timestamp: '09:15'),
    ];
  }

  List<ChatModel> get conversations => _conversations;

  void sendMessage(String convoId, String message) {
    // TODO: append message to conversation
    notifyListeners();
  }
}
