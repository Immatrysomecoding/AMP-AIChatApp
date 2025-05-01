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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar
          const Sidebar(selectedItem: "DATA",),

          // Main chat area
          const Expanded(
            child: KnowledgeList(),
          ),
        ],
      ),
    );
  }
}