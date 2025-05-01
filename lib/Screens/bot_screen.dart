import 'package:aichat/widgets/update_bot.dart';
import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/bot_list.dart';

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  String? _botId;
  String? _botName;
  String? _botDesc;
  String? _botInstructions;

  void _showUpdateBot(
    String id,
    String name,
    String desc,
    String instructions,
  ) {
    setState(() {
      _botId = id;
      _botName = name;
      _botDesc = desc;
      _botInstructions = instructions;
    });
  }

  void _goBackToBotList() {
    setState(() {
      _botId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar
          const Sidebar(selectedItem: 'BOT'),

          // Main content area
          Expanded(
            child:
                _botId == null
                    ? BotList(onUpdateBot: _showUpdateBot)
                    : UpdateBot(
                      botId: _botId!,
                      initialName: _botName!,
                      initialDescription: _botDesc!,
                      initialInstructions: _botInstructions!,
                      onBack: _goBackToBotList,
                    ),
          ),
        ],
      ),
    );
  }
}
