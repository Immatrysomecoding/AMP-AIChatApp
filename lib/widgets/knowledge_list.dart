import 'package:aichat/core/models/Knowledge.dart';
import 'package:aichat/core/providers/knowledge_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/widgets/update_knowledge_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aichat/widgets/knowledge_card.dart';
import 'package:aichat/widgets/create_knowledge_dialog.dart';

class KnowledgeList extends StatefulWidget {
  const KnowledgeList({super.key});

  @override
  State<KnowledgeList> createState() => _KnowledgeListState();
}

class _KnowledgeListState extends State<KnowledgeList> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCreateKnowledgeDialogVisible = false;

  @override
  void initState() {
    super.initState();

    // Initialize the search controller
    _searchController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKnowledge();
    }); // No await here
  }

  String getUserToken() {
    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    return userProvider.user?.accessToken ?? '';
  }

  List<Knowledge> get _filteredKnowledgeList {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(context);
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) return knowledgeProvider.knowledges;

    return knowledgeProvider.knowledges.where((knowledge) {
      return knowledge.knowledgeName.toLowerCase().contains(query) ||
          knowledge.description.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _loadKnowledge() async {
    if (!mounted) return;
    String accessToken = getUserToken();

    if (accessToken.isNotEmpty) {
      final knowledgeProvider = Provider.of<KnowledgeProvider>(
        context,
        listen: false,
      );
      await knowledgeProvider.fetchKnowledges(accessToken);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleCreateKnowledgeDialog() {
    setState(() {
      _isCreateKnowledgeDialogVisible = !_isCreateKnowledgeDialogVisible;
    });
  }

  void _createKnowledge(String name, String description) {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(
      context,
      listen: false,
    );
    final token = getUserToken();
    if (token.isNotEmpty) {
      knowledgeProvider.createKnowledge(token, name, description).then((_) {
        _loadKnowledge();
        _toggleCreateKnowledgeDialog();
      });
    }
  }

  void _updateKnowledge(String knowledgeId, String name, String description) {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(
      context,
      listen: false,
    );
    final token = getUserToken();
    if (token.isNotEmpty) {
      knowledgeProvider
          .updateKnowledge(token, knowledgeId, name, description)
          .then((_) {
            _loadKnowledge();
          });
    }
  }

  void _deleteKnowledge(String knowledgeId) {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(
      context,
      listen: false,
    );
    final token = getUserToken();
    if (token.isNotEmpty) {
      knowledgeProvider.deleteKnowledge(token, knowledgeId).then((_) {
        _loadKnowledge();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(context);
    final knowledgeList = _filteredKnowledgeList;

    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFFF7FBFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Knowledge Base",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1C2E),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search knowledge base",
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
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CreateKnowledgeBaseDialog(
                      onCancel: () => Navigator.of(context).pop(),
                      onSave: (name, description) {
                        _createKnowledge(name, description);
                      },
                    );
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Create Knowledge"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                knowledgeProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: knowledgeList.length,
                      itemBuilder: (context, index) {
                        final knowledge = knowledgeList[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: KnowledgeCard(
                            title: knowledge.knowledgeName,
                            id: knowledge.id,
                            subtitle: knowledge.description,
                            unitLabel:
                                "${knowledge.numUnits} unit${knowledge.numUnits == 1 ? '' : 's'}",
                            sizeLabel:
                                "${(knowledge.totalSize / 1024).toStringAsFixed(2)} KB",
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return UpdateKnowledgeBaseDialog(
                                    currentName: knowledge.knowledgeName,
                                    currentDescription: knowledge.description,
                                    onCancel: () => Navigator.of(context).pop(),
                                    onSave: (name, description) {
                                      _updateKnowledge(
                                        knowledge.id,
                                        name,
                                        description,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            onDelete: () {
                              _deleteKnowledge(knowledge.id);
                            },
                            // onTap: () {
                            //   Navigator.of(context).pushNamed(
                            //     '/knowledge_detail',
                            //     arguments: KnowledgeDetailS(
                            //       title: knowledge.knowledgeName,
                            //       description: knowledge.description,
                            //       id: knowledge.id,
                            //     ),
                            //   );
                            // },
                            onChat: () {
                              // handle chat
                            },
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
