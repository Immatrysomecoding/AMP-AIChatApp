import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/chat_history_list.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Sidebar
          //const Sidebar(selectedItem: 'Chat'),

          // Main content area
          const Expanded(
            child: ChatHistoryList(),
          ),
        ],
      ),
    );
  }
}