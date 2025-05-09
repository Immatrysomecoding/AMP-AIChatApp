import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/widgets/confirm_removal_dialog.dart';
import 'package:aichat/widgets/publishing_bots.dart';
import 'package:flutter/material.dart';
import 'package:aichat/core/models/Knowledge.dart';
import 'package:aichat/core/providers/bot_provider.dart';
import 'package:provider/provider.dart';
import 'package:aichat/widgets/bot_knowledge_list.dart';

class UpdateBot extends StatefulWidget {
  const UpdateBot({
    super.key,
    required this.botId,
    required this.initialName,
    required this.initialDescription,
    required this.initialInstructions,
    required this.onBack,
  });

  final String botId;
  final String initialName;
  final String initialDescription;
  final String initialInstructions;
  final VoidCallback onBack;

  @override
  _UpdateBotState createState() => _UpdateBotState();
}

class _UpdateBotState extends State<UpdateBot> {
  late TextEditingController _descriptionController;
  late TextEditingController _instructionsController;
  late String _description;
  late String _instructions;
  List<Knowledge> _importedKnowledge = [];
  bool _isLoadingKnowledge = true;
  late String _currentInitialInstructions; // track updates locally
  late String _currentInitialDescription; // track updates locally
  late String _botName;
  late String _initialBotName;

  @override
  void initState() {
    super.initState();

    _description = widget.initialDescription;
    _instructions = widget.initialInstructions;

    _currentInitialInstructions = widget.initialInstructions;
    _currentInitialDescription = widget.initialDescription;
    _botName = widget.initialName;
    _initialBotName = widget.initialName;

    _descriptionController = TextEditingController(text: _description);
    _instructionsController = TextEditingController(text: _instructions);

    _descriptionController.addListener(_onChanges);
    _instructionsController.addListener(_onChanges);

    _loadKnowledge();
  }

  void _loadKnowledge() async {
    final data = await fetchImportedKnowledge(context, widget.botId);
    setState(() {
      _importedKnowledge = data;
      _isLoadingKnowledge = false;
    });
  }

  void _onChanges() {
    setState(() {
      _description = _descriptionController.text;
      _instructions = _instructionsController.text;
    });
  }

  bool _isSaveEnabled() {
    return _description != _currentInitialDescription ||
        _instructions != _currentInitialInstructions ||
        _botName != _initialBotName;
  }

  void _editNameDialog() {
    final nameController = TextEditingController(text: _botName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Bot Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Bot Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _botName = nameController.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String getUserToken() {
    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    return userProvider.user?.accessToken ?? '';
  }

  Future<List<Knowledge>> fetchImportedKnowledge(
    BuildContext context,
    String botId,
  ) async {
    String accessToken = getUserToken();
    if (accessToken.isEmpty) return [];

    final botProvider = Provider.of<BotProvider>(context, listen: false);
    return await botProvider.getImportedKnowledge(accessToken, botId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                _botName + (_botName != _initialBotName ? '*' : ''),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editNameDialog,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Row(
        children: [
          // Knowledge Base Column
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Knowledge Base',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child:
                        _isLoadingKnowledge
                            ? const Center(child: CircularProgressIndicator())
                            : _importedKnowledge.isEmpty
                            ? const Center(child: Text("No knowledge sources"))
                            : ListView.builder(
                              itemCount: _importedKnowledge.length,
                              itemBuilder: (context, index) {
                                final knowledge = _importedKnowledge[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.storage),
                                  title: Text(knowledge.knowledgeName),
                                  subtitle: Text(
                                    knowledge.description.isNotEmpty
                                        ? knowledge.description
                                        : 'No description',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return ConfirmRemoveDialog(
                                            title: 'Remove Knowledge',
                                            content:
                                                "Are you sure you want to remove this knowledge source?",
                                            onCancel:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            onConfirm: () async {
                                              Navigator.of(
                                                context,
                                              ).pop(); // Close dialog

                                              final botProvider =
                                                  Provider.of<BotProvider>(
                                                    context,
                                                    listen: false,
                                                  );
                                              final tokenProvider = Provider.of<
                                                UserTokenProvider
                                              >(context, listen: false);
                                              final token =
                                                  tokenProvider
                                                      .user
                                                      ?.accessToken ??
                                                  '';

                                              if (token.isNotEmpty) {
                                                await botProvider
                                                    .deleteKnowledgeFromBot(
                                                      token,
                                                      widget.botId,
                                                      knowledge.id,
                                                    );
                                                _loadKnowledge(); // ✅ Refresh list
                                              }
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => Dialog(
                              child: KnowledgeBaseList(
                                botId: widget.botId,
                                importedKnowledge: _importedKnowledge,
                              ),
                            ),
                      ).then(
                        (_) => _loadKnowledge(),
                      ); // Reload knowledge when dialog closes
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add knowledge source'),
                  ),
                ],
              ),
            ),
          ),

          // Preview Column
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.smart_toy, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("No messages yet"),
                        Text("Start a conversation to test your bot!"),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText:
                                "Ask me anything, press '/' for prompts...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          // TODO: Implement send logic
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Settings Column
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Persona & Instructions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 6,
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      labelText: "Instructions",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    maxLines: 6,
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed:
                        _isSaveEnabled()
                            ? () async {
                              final botProvider = Provider.of<BotProvider>(
                                context,
                                listen: false,
                              );
                              String accessToken = getUserToken();

                              if (accessToken.isNotEmpty) {
                                await botProvider.updateBot(
                                  accessToken,
                                  widget.botId,
                                  _botName,
                                  _instructions,
                                  _description,
                                );

                                // Update internal "initial" values so Save button disables
                                setState(() {
                                  _currentInitialDescription = _description;
                                  _currentInitialInstructions = _instructions;
                                  _initialBotName = _botName;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bot updated successfully.'),
                                  ),
                                );
                              }
                            }
                            : null,
                    child: const Text("Save Changes"),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  PublishScreen(), // Replace with your widget
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.publish),
                        const SizedBox(
                          width: 8,
                        ), // Add spacing between the icon and text
                        const Text("Publish Bot"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}
