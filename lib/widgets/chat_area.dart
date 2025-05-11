import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/chat_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/providers/ai_model_provider.dart';
import 'package:aichat/core/providers/prompt_provider.dart';
import 'package:aichat/core/models/ChatMessage.dart';
import 'package:aichat/core/models/AIModel.dart';
import 'package:aichat/core/models/Prompt.dart';
import 'package:aichat/widgets/prompt_library_overlay.dart';
import 'package:aichat/core/providers/bot_provider.dart';
import 'package:aichat/widgets/message_bubble.dart';
import 'package:aichat/widgets/prompt_input_overlay.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:aichat/widgets/prompt_suggestion_overlay.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatArea extends StatefulWidget {
  const ChatArea({super.key});

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final TextEditingController _messageController = TextEditingController();
  bool _isPromptLibraryVisible = false;
  bool _isPromptInputOverlayVisible = false;
  final ScrollController _scrollController = ScrollController();
  bool _isFirstLoad = true;
  Prompt? _selectedPrompt;
  bool _isShowingPromptSuggestions = false;
  String _promptFilterText = '';
  final FocusNode _inputFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _promptOverlay;
  bool _isMenuVisible = false;
  final GlobalKey _inputFieldKey = GlobalKey();
  int _tokenUsage = 0;
  int _tokenLimit = 50; // Default limit
  bool _isUnlimited = false;
  int _availableTokens = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchTokenUsage();
    _messageController.addListener(_handleTextChange);
    _inputFocusNode.addListener(() {
      if (!_inputFocusNode.hasFocus) {
        _hidePromptSuggestions();
      }
    });
  }

  void _loadData() async {
    setState(() {
      _isFirstLoad = true;
    });

    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    final accessToken = userProvider.user?.accessToken ?? '';

    if (accessToken.isNotEmpty) {
      try {
        // First load AI models
        final aiModelProvider = Provider.of<AIModelProvider>(
          context,
          listen: false,
        );
        await aiModelProvider.fetchAvailableModels(accessToken);

        // Ensure a default model is selected
        await _ensureDefaultModelSelected(aiModelProvider, accessToken);

        // Then load conversations for the selected model
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.fetchConversations(accessToken);

        // Also load prompts
        final promptProvider = Provider.of<PromptProvider>(
          context,
          listen: false,
        );
        await promptProvider.fetchPublicPrompts(accessToken);
        await promptProvider.fetchPrivatePrompts(accessToken);
      } catch (e) {
        print('Error in loadData: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isFirstLoad = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
      }
    }
  }

  Future<void> _fetchTokenUsage() async {
    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    final accessToken = userProvider.user?.accessToken ?? '';

    if (accessToken.isEmpty) return;

    try {
      var headers = {
        'x-jarvis-guid': '',
        'Authorization': 'Bearer $accessToken',
      };
      var request = http.Request(
        'GET',
        Uri.parse('https://api.dev.jarvis.cx/api/v1/tokens/usage'),
      );
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final data = await response.stream.bytesToString();
        final json = jsonDecode(data);

        if (mounted) {
          setState(() {
            // Update to use available tokens directly
            _availableTokens = json['availableTokens'] ?? 0;
            _tokenLimit = json['totalTokens'] ?? 50;
            _tokenUsage = (_tokenLimit - _availableTokens);
          });
        }
      } else {
        print('Error fetching token usage: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception fetching token usage: $e');
    }
  }

  // Ensure a default model is selected when app initializes
  Future<void> _ensureDefaultModelSelected(
    AIModelProvider aiModelProvider,
    String accessToken,
  ) async {
    if (aiModelProvider.selectedModel != null) return;

    // Find the default model (GPT-4o mini) or use the first available model
    final defaultModel = aiModelProvider.availableModels.firstWhere(
      (model) => model.id == 'gpt-4o-mini',
      orElse:
          () => aiModelProvider.availableModels.firstWhere(
            (model) => model.isDefault,
            orElse:
                () =>
                    aiModelProvider.availableModels.isNotEmpty
                        ? aiModelProvider.availableModels.first
                        : AIModel(
                          id: 'gpt-4o-mini',
                          model: 'dify',
                          name: 'GPT-4o mini',
                          isDefault: true,
                        ),
          ),
    );

    // Set it in the AIModelProvider
    aiModelProvider.setSelectedModel(defaultModel);

    // Also set it in ChatProvider
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.setSelectedModel(defaultModel, accessToken);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChange);
    _inputFocusNode.dispose();
    _hidePromptSuggestions();
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void _handleKeyPress() {
    if (!_isShowingPromptSuggestions || _filteredPrompts.isEmpty) return;

    // Is the Tab key held?
    if (RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.tab)) {
      if (_selectedPromptIndex >= 0 &&
          _selectedPromptIndex < _filteredPrompts.length) {
        _selectPrompt(_filteredPrompts[_selectedPromptIndex]);
      }
    }
  }

  void _handleTextChange() {
    final text = _messageController.text;

    // Check if the text contains a slash command
    if (text.contains('/')) {
      final slashIndex = text.lastIndexOf('/');

      // Only show suggestions if the slash is at the start or after a space
      if (slashIndex == 0 || (slashIndex > 0 && text[slashIndex - 1] == ' ')) {
        // Extract the filter text after the slash
        final query = text.substring(slashIndex + 1);

        setState(() {
          _promptFilterText = query;
          _isShowingPromptSuggestions = true;
        });

        if (!_isMenuVisible) {
          _showPromptSuggestions();
        }
      } else {
        _hidePromptSuggestions();
      }
    } else {
      _hidePromptSuggestions();
    }
  }

  List<PopupMenuEntry<Prompt>> _buildPromptMenuItems() {
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);
    final publicPrompts = promptProvider.publicPrompts;

    // Filter prompts based on the filter text
    final filteredPrompts =
        publicPrompts
            .where(
              (prompt) => prompt.title.toLowerCase().contains(
                _promptFilterText.toLowerCase(),
              ),
            )
            .toList();

    if (filteredPrompts.isEmpty) {
      return [
        const PopupMenuItem<Prompt>(
          enabled: false,
          child: Text('No matching prompts found'),
        ),
      ];
    }

    // Limit to max 4 items
    final displayPrompts =
        filteredPrompts.length > 4
            ? filteredPrompts.sublist(0, 4)
            : filteredPrompts;

    return displayPrompts.map((prompt) {
      return PopupMenuItem<Prompt>(
        value: prompt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              prompt.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (prompt.description != null && prompt.description!.isNotEmpty)
              Text(
                prompt.description!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      );
    }).toList();
  }

  void _showPromptSuggestions() {
    if (_isMenuVisible) return;
    _isMenuVisible = true;

    final promptProvider = Provider.of<PromptProvider>(context, listen: false);
    final publicPrompts = promptProvider.publicPrompts;

    // Filter prompts based on the filter text
    final filteredPrompts =
        publicPrompts
            .where(
              (prompt) => prompt.title.toLowerCase().contains(
                _promptFilterText.toLowerCase(),
              ),
            )
            .toList();

    if (filteredPrompts.isEmpty) {
      _isMenuVisible = false;
      return;
    }

    // Show a dialog with transparent barrier so user can still interact with the field
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (context) {
        return PromptSuggestionDialog(
          prompts: filteredPrompts,
          onPromptSelected: (prompt) {
            Navigator.of(context).pop(); // Close the dialog
            _selectPrompt(prompt);
          },
          onDismiss: () {
            Navigator.of(context).pop(); // Close the dialog
            _hidePromptSuggestions();
          },
        );
      },
    ).then((_) {
      _isMenuVisible = false;
    });
  }

  List<Prompt> _filteredPrompts = [];
  int _selectedPromptIndex = 0;

  // Method to select a prompt
  void _selectPrompt(Prompt prompt) {
    final text = _messageController.text;
    final slashIndex = text.lastIndexOf('/');

    if (slashIndex >= 0) {
      // Replace the slash command with the prompt content
      final newText = text.substring(0, slashIndex) + prompt.content;
      _messageController.text = newText;

      // Position cursor at the end
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
    }

    // Show the prompt input overlay
    setState(() {
      _selectedPrompt = prompt;
      _isPromptInputOverlayVisible = true;
    });

    _hidePromptSuggestions();
  }

  void _hidePromptSuggestions() {
    if (_promptOverlay != null) {
      _promptOverlay!.remove();
      _promptOverlay = null;
    }

    setState(() {
      _isShowingPromptSuggestions = false;
      _isMenuVisible = false;
    });
  }

  void _togglePromptLibrary() {
    setState(() {
      _isPromptLibraryVisible = !_isPromptLibraryVisible;
    });
  }

  // Show the prompt input overlay when a prompt is selected
  void _showPromptInput(Prompt prompt) {
    setState(() {
      _selectedPrompt = prompt;
      _isPromptInputOverlayVisible = true;
    });
  }

  // Handle prompt selection from library
  void _handlePromptSelected(Prompt prompt) {
    // Close the prompt library if it's open
    if (_isPromptLibraryVisible) {
      setState(() {
        _isPromptLibraryVisible = false;
      });
    }

    // Show the input overlay
    _showPromptInput(prompt);
  }

  void _viewPromptDetails(String promptId) {
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);
    final prompts = promptProvider.publicPrompts;

    // Guard clause if no prompts are available
    if (prompts.isEmpty) {
      // No prompts available, just open the prompt library
      _togglePromptLibrary();
      return;
    }

    // Try to find prompt by ID
    try {
      final prompt = prompts.firstWhere(
        (p) => p.id == promptId,
        // If not found by ID, try to find by title containing "learn code"
        orElse:
            () => prompts.firstWhere(
              (p) => p.title.toLowerCase().contains("learn code"),
              // If still not found, just use the first prompt
              orElse: () => prompts.first,
            ),
      );

      // Show the prompt input overlay
      _showPromptInput(prompt);
    } catch (e) {
      // In case of any error, fallback to opening the prompt library
      print('Error finding prompt: $e');
      _togglePromptLibrary();
    }
  }

  void _startNewChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.startNewConversation();
    _scrollToBottom();
  }

  // Improved _sendMessage method with error handling
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Clear the input field immediately
    _messageController.clear();

    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    final accessToken = userProvider.user?.accessToken ?? '';

    if (accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send messages')),
      );
      return;
    }

    // Get the chat provider
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Don't send if already sending
    if (chatProvider.isSendingMessage) return;

    try {
      // Use the direct method instead of the service method
      await chatProvider.sendMessageDirect(accessToken, message);
      await _fetchTokenUsage();

      // Scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      print('Unexpected error in _sendMessage: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Improved model selection to prevent UI flashing
  Future<void> _selectModel(AIModel model) async {
    if (mounted) {
      setState(() {
        _isFirstLoad = true; // Show loading state while changing models
      });
    }

    try {
      final userProvider = Provider.of<UserTokenProvider>(
        context,
        listen: false,
      );
      final accessToken = userProvider.user?.accessToken ?? '';

      if (accessToken.isEmpty) return;

      // Update the model in AIModelProvider
      final aiModelProvider = Provider.of<AIModelProvider>(
        context,
        listen: false,
      );
      aiModelProvider.setSelectedModel(model);

      // Update the model in ChatProvider with async handling
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.setSelectedModel(model, accessToken);

      // After everything is loaded, update state
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      print('Error changing model: $e');

      // Ensure we exit loading state even if there's an error
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiModelProvider = Provider.of<AIModelProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final promptProvider = Provider.of<PromptProvider>(context);

    // Get the current messages to display
    final List<ChatMessage> messages =
        chatProvider.currentConversation?.messages ?? [];

    // When new messages arrive, scroll to bottom
    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    // Show loading indicator overlay instead of replacing the entire UI
    if (_isFirstLoad) {
      return Stack(
        children: [
          // Show a placeholder UI while loading
          _buildLoadingPlaceholder(),

          // Show a centered loading indicator
          const Center(
            child: Card(
              color: Colors.white,
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading chat...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chat messages or welcome screen
            Expanded(
              child:
                  messages.isEmpty
                      ? _buildWelcomeScreen()
                      : _buildChatMessages(
                        messages,
                        chatProvider.isSendingMessage,
                      ),
            ),

            // New Chat UI layout matching the image
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  // Top row with buttons and controls
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      children: [
                        // Left side: model selector and new chat button
                        Expanded(
                          child: Row(
                            children: [
                              _buildModelSelector(aiModelProvider),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _startNewChat,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('New Chat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right side: prompt library and chat history icons
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: _togglePromptLibrary,
                              color: Colors.grey,
                              tooltip: 'Prompt Library',
                            ),
                            IconButton(
                              icon: const Icon(Icons.history),
                              onPressed: () {
                                Navigator.pushNamed(context, '/history');
                              },
                              color: Colors.grey,
                              tooltip: 'Chat History',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Message input field - INCREASED HEIGHT
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.end, // Align to bottom
                      children: [
                        Expanded(
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (RawKeyEvent event) {
                              if (event is RawKeyDownEvent &&
                                  event.logicalKey == LogicalKeyboardKey.tab &&
                                  _isShowingPromptSuggestions &&
                                  _filteredPrompts.isNotEmpty) {
                                // Prevent default tab behavior and select the prompt
                                _selectPrompt(
                                  _filteredPrompts[_selectedPromptIndex],
                                );
                                // Prevent the event from being processed further
                                return;
                              }
                            },
                            child: CompositedTransformTarget(
                              link: _layerLink,
                              child: TextField(
                                key: _inputFieldKey,
                                controller: _messageController,
                                focusNode: _inputFocusNode,
                                decoration: InputDecoration(
                                  hintText:
                                      "Ask me anything, press '/' for prompts...",
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16, // INCREASED PADDING
                                  ),
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                maxLines: 5, // INCREASED MAX LINES
                                minLines: 2, // MINIMUM NUMBER OF LINES
                                textAlignVertical:
                                    TextAlignVertical.top, // Start from top
                                onSubmitted: (_) {
                                  _hidePromptSuggestions();
                                  _sendMessage();
                                },
                                enabled: !chatProvider.isSendingMessage,
                                onTap: () {
                                  // Reshow suggestions if "/" is in text and field is tapped
                                  if (_messageController.text.contains('/')) {
                                    _handleTextChange();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.attach_file),
                              onPressed:
                                  chatProvider.isSendingMessage ? null : () {},
                              color: Colors.grey,
                            ),

                            IconButton(
                              icon: const Icon(Icons.code),
                              onPressed:
                                  chatProvider.isSendingMessage ? null : () {},
                              color: Colors.grey,
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                right: 8.0,
                                bottom: 8.0,
                              ),
                              child: IconButton(
                                icon:
                                    chatProvider.isSendingMessage
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.blue,
                                                ),
                                          ),
                                        )
                                        : Icon(Icons.send, color: Colors.blue),
                                onPressed:
                                    chatProvider.isSendingMessage
                                        ? null
                                        : () {
                                          _hidePromptSuggestions();
                                          _sendMessage();
                                        },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Token usage and upgrade button - UPDATED to match screenshot
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tokens available with flame icon
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${_availableTokens}",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        // Infinity symbol
                        Row(
                          children: [
                            Icon(
                              Icons.all_inclusive,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),

                        // Upgrade button
                        TextButton.icon(
                          onPressed: () {
                            // Handle upgrade action
                          },
                          icon: const Icon(Icons.rocket_launch, size: 16),
                          label: const Text('Upgrade'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Prompt library overlay
        PromptLibraryOverlay(
          isVisible: _isPromptLibraryVisible,
          onClose: _togglePromptLibrary,
          onPromptSelected: _handlePromptSelected,
        ),

        // Prompt input overlay
        if (_selectedPrompt != null)
          PromptInputOverlay(
            isVisible: _isPromptInputOverlayVisible,
            onClose: () => setState(() => _isPromptInputOverlayVisible = false),
            prompt: _selectedPrompt!,
            onSubmit: (promptText) {
              _messageController.text = promptText;
              _sendMessage();
            },
          ),
      ],
    );
  }

  Widget _buildWelcomeScreen() {
    final promptProvider = Provider.of<PromptProvider>(context);
    final publicPrompts = promptProvider.publicPrompts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text('👋', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'Hi, good afternoon!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'I\'m Jarvis, your personal assistant.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // Pro version card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade to the Pro version for unlimited access with a 1-month free trial!',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Start Free Trial'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Use Jarvis on all platforms section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Use Jarvis on all platforms',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Download Jarvis on your desktop, mobile, and browser.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Don't know what to say section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Don\'t know what to say? Use a prompt!',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              TextButton(
                onPressed: _togglePromptLibrary,
                child: const Text('View all'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sample prompts - Show real prompts if available
          if (publicPrompts.isEmpty)
            Column(
              children: [
                _buildPromptButton(
                  'Learn Code FAST!',
                  onTap: () => _togglePromptLibrary(),
                ),
                const SizedBox(height: 12),
                _buildPromptButton(
                  'Story generator',
                  onTap: () => _togglePromptLibrary(),
                ),
                const SizedBox(height: 12),
                _buildPromptButton(
                  'Grammar corrector',
                  onTap: () => _togglePromptLibrary(),
                ),
              ],
            )
          else
            Column(
              children: [
                for (int i = 0; i < min(3, publicPrompts.length); i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _buildPromptButton(
                    publicPrompts[i].title,
                    prompt: publicPrompts[i],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChatMessages(
    List<ChatMessage> messages,
    bool isWaitingForResponse,
  ) {
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + (isWaitingForResponse ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length && isWaitingForResponse) {
              // Show typing indicator as part of the list, not a separate widget
              return Container(
                margin: const EdgeInsets.only(left: 28, top: 8, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTypingDot(0),
                          _buildTypingDot(1),
                          _buildTypingDot(2),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final message = messages[index];
            return MessageBubble(
              message: message,
              isUser: message.role == 'user',
            );
          },
        ),

        // Scroll to bottom button (show only when needed)
        if (_scrollController.hasClients &&
            (_scrollController.position.maxScrollExtent > 0) &&
            (_scrollController.position.pixels <
                _scrollController.position.maxScrollExtent - 200))
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _scrollToBottom,
              child: const Icon(Icons.arrow_downward, color: Colors.blue),
            ),
          ),
      ],
    );
  }

  // Simplified typing indicator that doesn't use AnimatedBuilder
  Widget _buildTypingDot(int index) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade500,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildModelSelector(AIModelProvider aiModelProvider) {
    return PopupMenuButton<AIModel>(
      enabled: !_isFirstLoad,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isFirstLoad
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade300,
                    ),
                  ),
                )
                : _getModelIcon(aiModelProvider.selectedModel?.id ?? ''),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                _isFirstLoad
                    ? 'Loading...'
                    : (aiModelProvider.selectedModel?.name ?? 'Select AI'),
                style: TextStyle(
                  color: _isFirstLoad ? Colors.grey : Colors.black87,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, size: 20, color: Colors.black87),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        // Create the popup menu with sections and styled items
        List<PopupMenuEntry<AIModel>> items = [
          const PopupMenuItem<AIModel>(
            enabled: false,
            height: 32,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Base AI Models',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ];

        // Add base AI models with icons
        final baseModels =
            aiModelProvider.availableModels
                .where((model) => !model.id.startsWith('bot_'))
                .toList();

        for (var model in baseModels) {
          items.add(
            PopupMenuItem<AIModel>(
              value: model,
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _getModelIconForDropdown(model.id),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      model.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Add custom bots section if available - ensure we have real bots, not placeholder ones
        final customBots =
            aiModelProvider.availableModels
                .where((model) => model.id.startsWith('bot_'))
                .toList();

        // Always fetch the latest bots
        _fetchUserBots();

        // Only add the Your Bots section if we have actual bots
        if (customBots.isNotEmpty) {
          items.add(
            const PopupMenuItem<AIModel>(
              enabled: false,
              height: 32,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Your Bots',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );

          for (var bot in customBots) {
            // Skip any bot with a generic name like "Jarvis Bot"
            if (bot.name.toLowerCase() == "jarvis bot") continue;

            items.add(
              PopupMenuItem<AIModel>(
                value: bot,
                height: 46,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        bot.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        return items;
      },
      onSelected: (AIModel model) {
        _selectModel(model);
      },
    );
  }

  void _fetchUserBots() {
    Future.delayed(Duration.zero, () async {
      final userProvider = Provider.of<UserTokenProvider>(
        context,
        listen: false,
      );
      final accessToken = userProvider.user?.accessToken ?? '';

      if (accessToken.isEmpty) return;

      try {
        // Fetch bots using BotProvider
        final botProvider = Provider.of<BotProvider>(context, listen: false);
        await botProvider.fetchBots(accessToken);

        // Make sure we have actual bots before continuing
        if (botProvider.bots.isEmpty) {
          print("No bots found for user.");
          return;
        }

        // Convert bots to AIModel format for the dropdown
        List<AIModel> botModels =
            botProvider.bots.map((bot) {
              print(
                "Creating AIModel for bot: ${bot.id} - ${bot.assistantName}",
              );
              return AIModel(
                id: 'bot_${bot.id}', // Store the full bot ID
                model: 'knowledge-base',
                name: bot.assistantName,
                description: bot.description,
              );
            }).toList();

        // Update the AIModelProvider with these bots
        final aiModelProvider = Provider.of<AIModelProvider>(
          context,
          listen: false,
        );

        // Filter out ALL existing bot models (to remove any "Jarvis Bot" placeholders)
        List<AIModel> currentModels = aiModelProvider.availableModels;
        List<AIModel> baseModels =
            currentModels
                .where((model) => !model.id.startsWith('bot_'))
                .toList();

        // Combine base models with fetched bot models
        List<AIModel> updatedModels = [...baseModels, ...botModels];

        // Update the models in the provider
        aiModelProvider.updateAvailableModels(updatedModels);
      } catch (e) {
        print('Error fetching bots: $e');
      }
    });
  }

  Widget _getModelIconForDropdown(String modelId) {
    if (modelId.contains('gpt-4o-mini')) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: const Center(
          child: Text(
            "G",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (modelId.contains('gpt-4o')) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.purple,
        ),
        child: const Center(
          child: Text(
            "G",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (modelId.contains('gemini-1.5-flash')) {
      return const Icon(Icons.flight_takeoff, color: Colors.blue, size: 20);
    } else if (modelId.contains('gemini-1.5-pro')) {
      return const Icon(Icons.bolt, color: Colors.black, size: 20);
    } else if (modelId.contains('claude-3-haiku')) {
      return const Icon(Icons.auto_awesome, color: Colors.orange, size: 20);
    } else if (modelId.contains('claude-3.5-sonnet')) {
      return const Icon(Icons.auto_awesome, color: Colors.orange, size: 20);
    } else if (modelId.contains('deepseek')) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
        child: const Center(
          child: Icon(Icons.water_drop, color: Colors.white, size: 14),
        ),
      );
    } else {
      return const Icon(Icons.assistant, color: Colors.black87, size: 20);
    }
  }

  Widget _getModelIcon(String modelId) {
    if (modelId.contains('gpt-4o-mini')) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: const Center(
          child: Text(
            "G",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (modelId.contains('gpt-4o')) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.purple,
        ),
        child: const Center(
          child: Text(
            "G",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (modelId.contains('gemini-1.5-flash')) {
      return const Icon(Icons.flight_takeoff, color: Colors.blue, size: 20);
    } else if (modelId.contains('gemini-1.5-pro')) {
      return const Icon(Icons.bolt, color: Colors.black, size: 20);
    } else if (modelId.contains('claude-3-haiku')) {
      return const Icon(Icons.auto_awesome, color: Colors.orange, size: 20);
    } else if (modelId.contains('claude-3.5-sonnet')) {
      return const Icon(Icons.auto_awesome, color: Colors.orange, size: 20);
    } else if (modelId.contains('deepseek')) {
      return const Icon(Icons.explore, color: Colors.blue, size: 20);
    } else if (modelId.startsWith('bot_')) {
      return const Icon(Icons.smart_toy_outlined, color: Colors.blue, size: 20);
    } else {
      return const Icon(Icons.assistant, color: Colors.black87, size: 20);
    }
  }

  Widget _buildPromptButton(
    String text, {
    String? promptId,
    Prompt? prompt,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (prompt != null) {
          _handlePromptSelected(prompt);
        } else if (promptId != null) {
          _viewPromptDetails(promptId);
        } else if (onTap != null) {
          onTap();
        } else {
          // If no specific action is defined, just open the prompt library
          _togglePromptLibrary();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
          ],
        ),
      ),
    );
  }

  // Loading placeholder UI when switching models or loading chats
  Widget _buildLoadingPlaceholder() {
    return Column(
      children: [
        // Main content area (blurred/placeholder)
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading conversations...',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Message input area placeholder
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          height: 72,
          child: Row(
            children: [
              Container(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const Spacer(),
              Container(
                width: 300,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
