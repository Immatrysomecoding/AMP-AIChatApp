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
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          isLargeScreen
              ? null
              : AppBar(
                title: const Text('Bots'),
                backgroundColor: Colors.blue.shade50,
                iconTheme: const IconThemeData(color: Colors.blue),
              ),
      drawer:
          isLargeScreen
              ? null
              : const Drawer(child: Sidebar(selectedItem: 'BOT')),
      body:
          isLargeScreen
              ? Row(
                children: [
                  const Sidebar(selectedItem: 'BOT'),
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
              )
              : _botId == null
              ? BotList(onUpdateBot: _showUpdateBot)
              : UpdateBot(
                botId: _botId!,
                initialName: _botName!,
                initialDescription: _botDesc!,
                initialInstructions: _botInstructions!,
                onBack: _goBackToBotList,
              ),
    );
  }
}
