import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/chat_area.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/models/UserToken.dart';

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
  }

  @override
Widget build(BuildContext context) {
  final isLargeScreen = MediaQuery.of(context).size.width >= 600;

  return Scaffold(
    backgroundColor: Colors.white,
    appBar: isLargeScreen
        ? null
        : AppBar(
            title: const Text('Jarvis'),
            backgroundColor: Colors.blue.shade50,
            iconTheme: const IconThemeData(color: Colors.blue),
          ),
    drawer: isLargeScreen ? null : Drawer(child: Sidebar(selectedItem: 'Chat')),
    body: isLargeScreen
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
