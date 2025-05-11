import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/widgets/confirm_removal_dialog.dart';
import 'package:aichat/widgets/publishing_bots.dart';
import 'package:flutter/material.dart';
import 'package:aichat/core/models/Knowledge.dart';
import 'package:aichat/core/providers/bot_provider.dart';
import 'package:provider/provider.dart';
import 'package:aichat/widgets/bot_knowledge_list.dart';

// Simple message model for the chat preview
class ChatMessage {
  final String content;
  final bool isUser;
  final String senderName;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.senderName,
  });
}

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
  late TextEditingController _messageController;
  late String _description;
  late String _instructions;
  List<Knowledge> _importedKnowledge = [];
  bool _isLoadingKnowledge = true;
  late String _currentInitialInstructions; // track updates locally
  late String _currentInitialDescription; // track updates locally
  late String _botName;
  late String _initialBotName;

  // Chat variables
  List<ChatMessage> _messages = [];
  bool _isSending = false;
  String? _currentThreadId;

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
    _messageController = TextEditingController();

    _descriptionController.addListener(_onChanges);
    _instructionsController.addListener(_onChanges);

    _loadKnowledge();

    // Start with an empty thread
    _initializeThread();
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

  Future<void> _initializeThread() async {
    setState(() {
      // Don't clear messages - we'll add the initial exchange to the existing chat
      _isSending = true;
    });

    try {
      final botProvider = Provider.of<BotProvider>(context, listen: false);
      final token = getUserToken();

      // Create a new thread
      final response = await botProvider.createThreadForBot(
        token,
        widget.botId,
        "Hello",
      );

      // Extract thread ID from response
      if (response != null && response.containsKey('openAiThreadId')) {
        _currentThreadId = response['openAiThreadId'];

        // Add initial messages only if the chat is empty
        if (_messages.isEmpty) {
          setState(() {
            _messages.add(
              ChatMessage(content: "Hello", isUser: true, senderName: "You"),
            );

            _messages.add(
              ChatMessage(
                content:
                    response['message'] ?? "Hello! How can I assist you today?",
                isUser: false,
                senderName: _botName,
              ),
            );
          });
        }
      }
    } catch (e) {
      print("Error creating thread: $e");

      // Fallback to placeholder conversation if API fails and chat is empty
      if (_messages.isEmpty) {
        setState(() {
          _messages.add(
            ChatMessage(content: "Hello", isUser: true, senderName: "You"),
          );

          _messages.add(
            ChatMessage(
              content: "Hello! How can I assist you today?",
              isUser: false,
              senderName: _botName,
            ),
          );
        });
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // Send a message to the bot
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // Clear the input
    _messageController.clear();

    // Add user message to the list
    setState(() {
      _messages.add(
        ChatMessage(content: message, isUser: true, senderName: "You"),
      );
      _isSending = true;
    });

    try {
      final botProvider = Provider.of<BotProvider>(context, listen: false);
      final token = getUserToken();

      if (_currentThreadId == null) {
        // If we don't have a thread ID, create one first
        await _initializeThread();
      }

      // Add a placeholder bot message that will be updated with the streamed response
      final int botMessageIndex = _messages.length;
      setState(() {
        _messages.add(
          ChatMessage(content: "", isUser: false, senderName: _botName),
        );
      });

      String fullResponse = "";

      // Send the message with callback for streaming updates
      final response = await botProvider.askBot(
        token,
        widget.botId,
        message,
        _currentThreadId ?? "",
        "",
        onChunkReceived: (chunk) {
          // Update the message as each chunk arrives
          fullResponse += chunk;
          setState(() {
            if (botMessageIndex < _messages.length) {
              // Update the bot message in place as chunks arrive
              _messages[botMessageIndex] = ChatMessage(
                content: fullResponse,
                isUser: false,
                senderName: _botName,
              );
            }
          });
        },
      );

      // Make sure the final message is set correctly if the streaming didn't work properly
      if (response != null &&
          response.containsKey('message') &&
          response['message'].toString().isNotEmpty) {
        setState(() {
          if (botMessageIndex < _messages.length) {
            _messages[botMessageIndex] = ChatMessage(
              content: response['message'],
              isUser: false,
              senderName: _botName,
            );
          }
        });
      }
    } catch (e) {
      print("Error sending message: $e");

      // Add error message if failed
      setState(() {
        _messages.add(
          ChatMessage(
            content:
                "Sorry, there was an error processing your message. Please try again.",
            isUser: false,
            senderName: _botName,
          ),
        );
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Small screen -> Tabs
            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.storage), text: 'Knowledge'),
                      Tab(icon: Icon(Icons.chat), text: 'Preview'),
                      Tab(icon: Icon(Icons.settings), text: 'Settings'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildKnowledgeBase(),
                        _buildPreview(),
                        _buildSettings(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Large screen -> Original layout
            return Row(
              children: [
                Expanded(flex: 2, child: _buildKnowledgeBase()),
                Expanded(flex: 3, child: _buildPreview()),
                Expanded(flex: 2, child: _buildSettings()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildKnowledgeBase() {
    return Padding(
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
                                    onCancel: () => Navigator.of(context).pop(),
                                    onConfirm: () async {
                                      Navigator.of(
                                        context,
                                      ).pop(); // Close dialog

                                      final botProvider =
                                          Provider.of<BotProvider>(
                                            context,
                                            listen: false,
                                          );
                                      final tokenProvider =
                                          Provider.of<UserTokenProvider>(
                                            context,
                                            listen: false,
                                          );
                                      final token =
                                          tokenProvider.user?.accessToken ?? '';

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
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
    );
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview header
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Preview the assistant's responses in a chat interface.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Chat container with messages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Messages area
                  Expanded(
                    child:
                        _messages.isEmpty
                            ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.smart_toy,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text("No messages yet"),
                                  Text(
                                    "Start a conversation to test your bot!",
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color:
                                              message.isUser
                                                  ? Colors.blue
                                                  : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Center(
                                          child:
                                              message.isUser
                                                  ? const Icon(
                                                    Icons.person,
                                                    size: 18,
                                                    color: Colors.white,
                                                  )
                                                  : const Icon(
                                                    Icons.smart_toy,
                                                    size: 18,
                                                    color: Colors.grey,
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Message content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.senderName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(message.content),
                                            if (!message.isUser)
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.copy,
                                                    size: 16,
                                                  ),
                                                  onPressed: () {
                                                    // Copy to clipboard
                                                  },
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),

                  // New thread button
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('New Thread'),
                        onPressed: () {
                          setState(() {
                            _messages = [];
                            _currentThreadId = null;
                          });
                          _initializeThread();
                        },
                      ),
                    ),
                  ),

                  // Chat input
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText:
                                  "Ask me anything, press '/' for prompts...",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            enabled: !_isSending,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon:
                              _isSending
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.send),
                          onPressed: _isSending ? null : _sendMessage,
                        ),
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

  Widget _buildSettings() {
    return Padding(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PublishScreen(botId: widget.botId),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.publish),
                SizedBox(width: 8),
                Text("Publish Bot"),
              ],
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
    _messageController.dispose();
    super.dispose();
  }
}
