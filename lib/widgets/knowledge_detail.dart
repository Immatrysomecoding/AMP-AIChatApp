import 'package:aichat/widgets/add_knowledge_source.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/providers/knowledge_provider.dart';
import 'package:aichat/core/models/KnowledgeUnit.dart';

class KnowledgeBaseDetail extends StatefulWidget {
  const KnowledgeBaseDetail({
    super.key,
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  @override
  State<KnowledgeBaseDetail> createState() => _KnowledgeBaseDetailState();
}

class _KnowledgeBaseDetailState extends State<KnowledgeBaseDetail> {
  late Future<List<KnowledgeUnit>> _knowledgeUnitsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _knowledgeUnitsFuture = _fetchKnowledgeUnits();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<List<KnowledgeUnit>> _fetchKnowledgeUnits() async {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(
      context,
      listen: false,
    );
    final token =
        Provider.of<UserTokenProvider>(
          context,
          listen: false,
        ).user?.accessToken ??
        '';

    return knowledgeProvider.getUnitsOfKnowledge(token, widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              widget.title,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search knowledge units by name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final safeContext = context; // Save context before dialog

                    showDialog(
                      context: safeContext,
                      builder:
                          (_) => KnowledgeSourceDialog(
                            onWebsiteSave: (name, url) {
                              final accessToken =
                                  Provider.of<UserTokenProvider>(
                                    safeContext,
                                    listen: false,
                                  ).user?.accessToken ??
                                  '';

                              Provider.of<KnowledgeProvider>(
                                safeContext,
                                listen: false,
                              ).uploadWebSiteToKnowledge(
                                accessToken,
                                widget.id,
                                name,
                                url,
                              );
                            },
                            onLocalFileImport: (file) {
                              final accessToken =
                                  Provider.of<UserTokenProvider>(
                                    safeContext,
                                    listen: false,
                                  ).user?.accessToken ??
                                  '';

                              // Call a new upload method for local files
                              Provider.of<KnowledgeProvider>(
                                safeContext,
                                listen: false,
                              ).uploadLocalFileToKnowledge(
                                accessToken,
                                widget.id,
                                file,
                              );
                            },
                          ),
                    );
                  },
                  // handle add
                  icon: const Icon(Icons.add),
                  label: const Text("Add Knowledge Unit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D72FA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<KnowledgeUnit>>(
                future: _knowledgeUnitsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No knowledge units found.');
                  }

                  // **Filtering knowledge units**
                  final filteredUnits =
                      snapshot.data!
                          .where(
                            (unit) =>
                                unit.name.toLowerCase().contains(_searchQuery),
                          )
                          .toList();

                  return ListView(
                    children:
                        filteredUnits
                            .map(
                              (unit) => KnowledgeUnitCard(
                                fileName: unit.name,
                                fileSize: "Unknown Size",
                                isActive: unit.status,
                              ),
                            )
                            .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KnowledgeUnitCard extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final bool isActive;

  const KnowledgeUnitCard({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file),
        title: Text(fileName),
        subtitle: Row(
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: isActive ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(fileSize),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: isActive, onChanged: (value) {}),
            IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
