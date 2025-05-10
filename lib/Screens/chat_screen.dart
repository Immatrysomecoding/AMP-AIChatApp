import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/chat_area.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/models/UserToken.dart';
import 'package:aichat/core/providers/chat_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  UserToken? user;

  @override
  void initState() {
    super.initState();
    user = Provider.of<UserTokenProvider>(context, listen: false).user;

    // Add a post-frame callback to avoid modifying state during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if there's an existing conversation (from history) before starting a new one
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (chatProvider.currentConversation != null &&
          chatProvider.currentConversation!.messages.isNotEmpty) {
        print(
          "Found existing conversation in provider with ${chatProvider.currentConversation!.messages.length} messages",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    // Debug the current conversation
    final chatProvider = Provider.of<ChatProvider>(context);
    if (chatProvider.currentConversation != null) {
      print(
        "ChatScreen build: loaded conversation ${chatProvider.currentConversation!.id}",
      );
      print(
        "Message count: ${chatProvider.currentConversation!.messages.length}",
      );
    } else {
      print("ChatScreen build: NO conversation loaded");
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          isLargeScreen
              ? null
              : AppBar(
                title: Text(
                  chatProvider.currentConversation?.title ?? 'Jarvis',
                ),
                backgroundColor: Colors.blue.shade50,
                iconTheme: const IconThemeData(color: Colors.blue),
              ),
      drawer:
          isLargeScreen ? null : Drawer(child: Sidebar(selectedItem: 'Chat')),
      body:
          isLargeScreen
              ? Row(
                children: const [
                  Sidebar(selectedItem: 'Chat'),
                  Expanded(child: ChatArea()),
                ],
              )
              : const ChatArea(),
    );
  }
}
