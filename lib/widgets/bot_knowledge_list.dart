import 'package:aichat/core/models/Knowledge.dart';
import 'package:aichat/core/providers/knowledge_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/providers/bot_provider.dart';
import 'package:aichat/widgets/create_knowledge_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KnowledgeBaseList extends StatefulWidget {
  final String botId;
  final List<Knowledge> importedKnowledge;

  const KnowledgeBaseList({
    super.key,
    required this.botId,
    required this.importedKnowledge,
  });

  @override
  State<KnowledgeBaseList> createState() => _KnowledgeBaseListState();
}

class _KnowledgeBaseListState extends State<KnowledgeBaseList> {
  late List<Knowledge> _imported;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _imported = widget.importedKnowledge;

    _searchController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKnowledge();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _userToken {
    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    return userProvider.user?.accessToken ?? '';
  }

  Future<void> _loadKnowledge() async {
    if (!mounted) return;
    final token = _userToken;
    if (token.isNotEmpty) {
      await Provider.of<KnowledgeProvider>(context, listen: false).fetchKnowledges(token);
    }
  }

  bool _isKnowledgeImported(String knowledgeId) {
    return _imported.any((k) => k.id == knowledgeId);
  }

  Future<void> _importKnowledge(Knowledge knowledge) async {
    final token = _userToken;
    if (token.isEmpty) return;

    final botProvider = Provider.of<BotProvider>(context, listen: false);
    await botProvider.importKnowledgeToBot(token, widget.botId, knowledge.id);

    setState(() {
      _imported.add(knowledge);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported "${knowledge.knowledgeName}"')),
    );
  }

  Future<void> _createKnowledge(String name, String description) async {
    final token = _userToken;
    if (token.isEmpty) return;

    final knowledgeProvider = Provider.of<KnowledgeProvider>(context, listen: false);
    await knowledgeProvider.createKnowledge(token, name, description);
    await _loadKnowledge();
  }

  @override
  Widget build(BuildContext context) {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(context);
    final knowledgeList = knowledgeProvider.knowledges.where((k) {
      final query = _searchController.text.toLowerCase();
      return k.knowledgeName.toLowerCase().contains(query) ||
          k.description.toLowerCase().contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFFF7FBFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Knowledge Base",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1C2E),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search knowledge...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => CreateKnowledgeBaseDialog(
                    onCancel: () => Navigator.of(context).pop(),
                    onSave: (name, description) async {
                      Navigator.of(context).pop(); // Close dialog
                      await _createKnowledge(name, description);
                    },
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Create Knowledge"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: knowledgeProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : knowledgeList.isEmpty
                    ? const Center(child: Text("No knowledge found."))
                    : ListView.builder(
                        itemCount: knowledgeList.length,
                        itemBuilder: (context, index) {
                          final knowledge = knowledgeList[index];
                          final imported = _isKnowledgeImported(knowledge.id);

                          return ListTile(
                            title: Text(knowledge.knowledgeName),
                            subtitle: Text(
                              knowledge.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: imported
                                ? const Text(
                                    "Imported",
                                    style: TextStyle(color: Colors.grey),
                                  )
                                : Tooltip(
                                    message: "Import the knowledge to bot",
                                    child: IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () => _importKnowledge(knowledge),
                                    ),
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
