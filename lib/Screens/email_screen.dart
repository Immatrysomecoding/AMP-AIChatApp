import 'package:aichat/widgets/Email/email.dart';
import 'package:aichat/widgets/sidebar.dart';
import 'package:flutter/material.dart';

class EmailScreen extends StatelessWidget {
  const EmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isLargeScreen
          ? null
          : AppBar(
              title: const Text('AI Email Assistant'),
              backgroundColor: Colors.blue.shade50,
              iconTheme: const IconThemeData(color: Colors.blue),
            ),
      drawer: isLargeScreen ? null : const Drawer(child: Sidebar(selectedItem: 'Email')),
      body: isLargeScreen
          ? Row(
              children: const [
                Sidebar(selectedItem: 'Email'),
                Expanded(child: AiEmailAssistantScreen()),
              ],
            )
          :  AiEmailAssistantScreen(),
    );
  }
}
