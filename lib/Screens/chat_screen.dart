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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    user = Provider.of<UserTokenProvider>(context, listen: false).user;

    // Add a post-frame callback to handle navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNavigationArgs();
    });
  }

  void _handleNavigationArgs() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Check if we have navigation arguments (conversation data)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final conversationId = args['conversationId'] as String?;
      if (conversationId != null) {
        // Load the conversation
        _loadConversation(conversationId);
      }
    } else {
      // Check if there's an existing conversation in the provider
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (chatProvider.currentConversation != null &&
          chatProvider.currentConversation!.messages.isNotEmpty) {
        print(
          "Found existing conversation in provider with ${chatProvider.currentConversation!.messages.length} messages",
        );
      }
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    final token = userProvider.user?.accessToken ?? '';

    if (token.isEmpty) return;

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.loadConversation(token, conversationId);
    } catch (e) {
      print("Error loading conversation: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversation: $e')),
        );
      }
    }
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
