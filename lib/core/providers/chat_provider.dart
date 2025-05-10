import 'package:flutter/material.dart';
import 'package:aichat/core/models/ChatMessage.dart';
import 'package:aichat/core/models/AIModel.dart';
import 'package:aichat/core/services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<AIModel> _availableModels = [];
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  AIModel? _selectedModel;
  bool _isLoading = false;
  int _remainingUsage = 50;
  bool _isSendingMessage = false;
  bool _isSelectedModelBot = false;

  List<AIModel> get availableModels => _availableModels;
  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  AIModel? get selectedModel => _selectedModel;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  int get remainingUsage => _remainingUsage;

  Future<void> fetchAvailableModels(String token) async {
    _setLoading(true);
    try {
      _availableModels = await _chatService.getAvailableModels(token);

      if (_selectedModel == null && _availableModels.isNotEmpty) {
        _selectedModel = _availableModels.firstWhere(
          (model) => model.isDefault,
          orElse: () => _availableModels.first,
        );
      }
    } catch (e) {
      print('Error fetching available models: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Improved model selection with error handling
  Future<void> setSelectedModel(AIModel model, String token) async {
    try {
      // Store current conversation if any, to restore it later if possible
      final String? currentConversationId = _currentConversation?.id;

      // Clear current conversation before switching model to avoid UI glitches
      _currentConversation = null;

      // Set the new model
      _selectedModel = model;

      // Identify if this is a bot model and extract the real bot ID
      _isSelectedModelBot = model.id.startsWith('bot_');
      if (_isSelectedModelBot) {
        // Extract the actual bot ID by removing the 'bot_' prefix
        _botId = model.id.substring(4); // 'bot_'.length == 4
        print("Selected bot with ID: $_botId");
      } else {
        _botId = null;
      }

      notifyListeners();

      // For bots, don't try to fetch conversation history
      if (!_isSelectedModelBot) {
        // Only fetch conversations for regular models
        await fetchConversations(token);
      }

      // Start with a fresh conversation for bots
      if (_isSelectedModelBot) {
        startNewConversation();
      }
    } catch (e) {
      print('Error setting model: $e');
      // In case of error, ensure UI is still updated
      notifyListeners();
    }
  }

  String? _botId;

  Future<void> fetchConversations(String token) async {
    if (_selectedModel == null) return;
    if (_isSelectedModelBot) return; // Skip for bots

    _setLoading(true);
    try {
      _conversations = await _chatService.getConversations(
        token,
        _selectedModel!.id,
        _selectedModel!.model,
      );

      // Sort conversations by date (newest first)
      _conversations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error fetching conversations: $e');
      _conversations = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadConversation(String token, String conversationId) async {
    if (_selectedModel == null) return;

    _setLoading(true);
    try {
      // Find the conversation in our list
      Conversation? existingConversation = _conversations.firstWhere(
        (conv) => conv.id == conversationId,
        orElse:
            () => Conversation(
              id: conversationId,
              title: 'Loading...',
              createdAt: DateTime.now(),
              assistant: AIAssistant(
                id: _selectedModel!.id,
                model: _selectedModel!.model,
                name: _selectedModel!.name,
              ),
            ),
      );

      List<ChatMessage> messages = await _chatService.getConversationMessages(
        token,
        conversationId,
        _selectedModel!.id,
        _selectedModel!.model,
      );

      existingConversation.messages = messages;
      _currentConversation = existingConversation;
    } catch (e) {
      print('Error loading conversation: $e');

      // Create empty conversation as fallback
      _currentConversation = Conversation(
        id: conversationId,
        title: 'Error loading conversation',
        createdAt: DateTime.now(),
        assistant: AIAssistant(
          id: _selectedModel!.id,
          model: _selectedModel!.model,
          name: _selectedModel!.name,
        ),
        messages: [],
      );
    } finally {
      _setLoading(false);
    }
  }

  // Start a new conversation
  void startNewConversation() {
    if (_selectedModel == null) return;

    _currentConversation = Conversation(
      id: '', // Will be assigned by the backend
      title: 'New Conversation',
      createdAt: DateTime.now(),
      assistant: AIAssistant(
        id: _selectedModel!.id,
        model: _selectedModel!.model,
        name: _selectedModel!.name,
      ),
      messages: [],
    );

    notifyListeners();
  }

  // Send a message with improved error handling to prevent UI flashes
  Future<void> sendMessage(
    String token,
    String content, [
    List<String> files = const [],
  ]) async {
    if (_selectedModel == null) return;
    if (content.trim().isEmpty) return;

    // Don't allow sending if we're already processing a message
    if (_isSendingMessage) return;

    _isSendingMessage = true;
    notifyListeners();

    // Start a new conversation if none is active
    if (_currentConversation == null) {
      startNewConversation();
    }

    // For bots, ensure we have the bot ID without the prefix
    String assistantId = _isSelectedModelBot ? _botId! : _selectedModel!.id;
    String modelType =
        _isSelectedModelBot ? 'knowledge-base' : _selectedModel!.model;

    print("Sending message to assistant ID: $assistantId (model: $modelType)");

    // Create a user message with the correct assistant info
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: 'user',
      files: files,
      createdAt: DateTime.now(),
      assistant: AIAssistant(
        id: assistantId, // Use the correct ID
        model: modelType,
        name: _selectedModel!.name,
      ),
    );

    _currentConversation!.messages.add(userMessage);
    notifyListeners();

    try {
      // Prepare messages for the API
      List<ChatMessage> messagesToSend = _currentConversation!.messages;

      // Ensure the assistant ID is consistent in all messages
      if (_isSelectedModelBot) {
        messagesToSend =
            messagesToSend.map((m) {
              return ChatMessage(
                id: m.id,
                content: m.content,
                role: m.role,
                files: m.files,
                createdAt: m.createdAt,
                assistant: AIAssistant(
                  id: assistantId, // Use consistent ID
                  model: modelType,
                  name: _selectedModel!.name,
                ),
              );
            }).toList();
      }

      var response = await _chatService.sendMessage(
        token,
        content,
        files,
        AIAssistant(
          id: assistantId, // Use the correct ID
          model: modelType,
          name: _selectedModel!.name,
        ),
        messagesToSend,
        _isSelectedModelBot
            ? null
            : (_currentConversation!.id.isNotEmpty
                ? _currentConversation!.id
                : null),
      );

      // Update remaining usage
      if (response.containsKey('remainingUsage')) {
        _remainingUsage = response['remainingUsage'];
      }

      // Only update conversation ID for regular models (not bots)
      if (!_isSelectedModelBot &&
          _currentConversation!.id.isEmpty &&
          response.containsKey('conversationId')) {
        _currentConversation!.id = response['conversationId'];
        // Set the title to the first message content (shortened if needed)
        _currentConversation!.title =
            content.length > 30 ? '${content.substring(0, 27)}...' : content;

        // Add this conversation to our list (only for regular models)
        _conversations.insert(0, _currentConversation!);
      }

      // Add the assistant's response
      if (response.containsKey('message')) {
        final assistantMessage = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_response',
          content: response['message'],
          role: 'model',
          createdAt: DateTime.now(),
          assistant: AIAssistant(
            id: assistantId, // Use the correct ID
            model: modelType,
            name: _selectedModel!.name,
          ),
        );

        _currentConversation!.messages.add(assistantMessage);
      }
    } catch (e) {
      print('Error sending message: $e');

      // Show error in chat
      final errorMessage = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_error',
        content: 'Error: Failed to send message. Please try again.',
        role: 'system',
        createdAt: DateTime.now(),
        assistant: AIAssistant(
          id: assistantId,
          model: modelType,
          name: 'System',
        ),
      );

      _currentConversation!.messages.add(errorMessage);
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Delete a conversation
  Future<void> deleteConversation(String token, String conversationId) async {
    try {
      // Here you would call an API to delete the conversation
      // For now we'll just remove it from the local list
      _conversations.removeWhere((conv) => conv.id == conversationId);

      // If we're deleting the current conversation, clear it
      if (_currentConversation != null &&
          _currentConversation!.id == conversationId) {
        _currentConversation = null;
      }

      notifyListeners();
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }
}
