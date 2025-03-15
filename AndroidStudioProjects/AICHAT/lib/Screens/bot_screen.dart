import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/bot_list.dart';

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar
          const Sidebar(selectedItem: 'BOT'),

          // Main content area
          const Expanded(
            child: BotList(),
          ),
        ],
      ),
    );
  }
}