import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/knowledge_list.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/models/UserToken.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  UserToken? user;

  @override
  void initState() {
    super.initState();
    user = Provider.of<UserTokenProvider>(context, listen: false).user;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isMobile ? const Drawer(child: Sidebar(selectedItem: "DATA")) : null,
      appBar: isMobile
          ? AppBar(
              title: const Text("Knowledge"),
              backgroundColor: Colors.blue.shade50,
              iconTheme: const IconThemeData(color: Colors.blue),
              elevation: 0,
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return const KnowledgeList(); // Only content on small screen
          } else {
            return Row(
              children: const [
                Sidebar(selectedItem: "DATA"),
                Expanded(child: KnowledgeList()),
              ],
            );
          }
        },
      ),
    );
  }
}
