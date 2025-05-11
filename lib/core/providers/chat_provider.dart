import 'package:flutter/material.dart';
import 'package:aichat/core/models/ChatMessage.dart';
import 'package:aichat/core/models/AIModel.dart';
import 'package:aichat/core/services/chat_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

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
    if (_selectedModel == null) {
      print("WARNING: No model selected in fetchConversations");
    }

    _setLoading(true);

    try {
      print("Fetching conversations with token length: ${token.length}");

      var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};

      var url = Uri.parse(
        'https://api.dev.jarvis.cx/api/v1/ai-chat/conversations?assistantId=${_selectedModel?.id ?? "gpt-4o-mini"}&assistantModel=${_selectedModel?.model ?? "dify"}',
      );
      print("Fetching from URL: ${url.toString()}");

      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print("Response body length: ${responseBody.length} characters");

        final decoded = json.decode(responseBody);
        List<dynamic> items = decoded['items'] ?? [];

        print("Found ${items.length} conversations in API response");

        // Create a list to hold updated conversations
        List<Conversation> apiConversations = [];

        for (var item in items) {
          try {
            // Add assistant info to each conversation for compatibility
            item['assistant'] = {
              'id': _selectedModel?.id ?? 'gpt-4o-mini',
              'model': _selectedModel?.model ?? 'dify',
              'name': _selectedModel?.name ?? 'GPT-4o mini',
            };

            Conversation conv = Conversation.fromJson(item);
            print("Parsed conversation: ${conv.id} - ${conv.title}");
            apiConversations.add(conv);
          } catch (e) {
            print("Error parsing conversation item: $e");
          }
        }

        // If we have a current conversation that's not in the API list, keep it
        if (_currentConversation != null) {
          bool currentExists = apiConversations.any(
            (conv) => conv.id == _currentConversation!.id,
          );

          if (!currentExists) {
            print("Current conversation not found in API, preserving it");
            apiConversations.insert(0, _currentConversation!);
          }
        }

        // Update the conversations list
        _conversations = apiConversations;

        // Sort conversations by date (newest first)
        _conversations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        print(
          'Error fetching conversations: ${response.statusCode} - ${response.reasonPhrase}',
        );
        // Don't clear conversations on error
      }
    } catch (e) {
      print('Exception in fetchConversations: $e');
      // Don't clear conversations on error
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void updateConversations(List<Conversation> conversations) {
    print(
      "ChatProvider: updateConversations called with ${conversations.length} conversations",
    );
    _conversations = conversations;
    notifyListeners();
    print(
      "ChatProvider: _conversations updated, now has ${_conversations.length} items",
    );
  }

  List<Conversation> get conversationsDebug {
    print(
      "ChatProvider: conversationsDebug getter called, returning ${_conversations.length} items",
    );
    return _conversations;
  }

  Future<void> loadConversation(String token, String conversationId) async {
    if (_selectedModel == null) {
      print("Warning: No model selected in loadConversation");
      return;
    }

    _setLoading(true);
    notifyListeners();

    try {
      // Check if we already have this conversation loaded
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

      print(
        "Loading conversation: ${existingConversation.id} - ${existingConversation.title}",
      );

      // Fetch the messages
      var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
      var url = Uri.parse(
        'https://api.dev.jarvis.cx/api/v1/ai-chat/conversations/$conversationId/messages?assistantId=${_selectedModel!.id}&assistantModel=${_selectedModel!.model}',
      );

      print("Fetching from URL: $url");
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseBody = response.body;
        var responseData = json.decode(responseBody);
        List<dynamic> items = responseData['items'] ?? [];

        print("Found ${items.length} messages in API response");

        List<ChatMessage> messages = [];

        // Process each message
        for (var item in items) {
          try {
            // User message
            var userMessage = ChatMessage(
              id: "${item['id'] ?? DateTime.now().millisecondsSinceEpoch}_user",
              content: item['query'] ?? '',
              role: 'user',
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                (item['createdAt'] ??
                        (DateTime.now().millisecondsSinceEpoch ~/ 1000)) *
                    1000,
              ),
              assistant: AIAssistant(
                id: _selectedModel!.id,
                model: _selectedModel!.model,
                name: _selectedModel!.name,
              ),
            );

            // Assistant message
            var aiMessage = ChatMessage(
              id:
                  "${item['id'] ?? DateTime.now().millisecondsSinceEpoch}_response",
              content: item['answer'] ?? 'No response available',
              role: 'model',
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                (item['createdAt'] ??
                            (DateTime.now().millisecondsSinceEpoch ~/ 1000)) *
                        1000 +
                    1,
              ),
              assistant: AIAssistant(
                id: _selectedModel!.id,
                model: _selectedModel!.model,
                name: _selectedModel!.name,
              ),
            );

            messages.add(userMessage);
            messages.add(aiMessage);
          } catch (e) {
            print("Error processing message: $e");
          }
        }

        // Update the conversation with the messages
        existingConversation.messages = messages;
        existingConversation.title =
            existingConversation.title == 'Loading...' && items.isNotEmpty
                ? (items[0]['query'] ?? 'Conversation').substring(
                  0,
                  math.min(20, (items[0]['query'] ?? 'Conversation').length),
                )
                : existingConversation.title;

        // Set as current conversation
        _currentConversation = existingConversation;

        // Make sure it's in our conversations list
        bool exists = _conversations.any(
          (conv) => conv.id == existingConversation.id,
        );
        if (!exists) {
          _conversations.insert(0, existingConversation);
        }
      } else {
        print(
          "Error loading messages: ${response.statusCode} - ${response.reasonPhrase}",
        );
        throw Exception(
          "Failed to load conversation messages: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Exception in loadConversation: $e");
      throw e;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Start a new conversation
  void startNewConversation() {
    if (_selectedModel == null) return;

    _currentConversation = Conversation(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}', // Clearer name for temporary ID
      title: 'New Conversation',
      createdAt: DateTime.now(),
      assistant: AIAssistant(
        id: _selectedModel!.id,
        model: _selectedModel!.model,
        name: _selectedModel!.name,
      ),
      messages: [],
    );

    // Add to conversations list immediately
    _conversations.insert(0, _currentConversation!);

    notifyListeners();
  }

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

    try {
      // Create user message and add to the conversation
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: 'user',
        files: files,
        createdAt: DateTime.now(),
        assistant: AIAssistant(
          id: _selectedModel!.id,
          model: _selectedModel!.model,
          name: _selectedModel!.name,
        ),
      );

      // Start a new conversation if none is active
      if (_currentConversation == null) {
        startNewConversation();
      }

      // Add user message to current conversation
      _currentConversation!.messages.add(userMessage);
      notifyListeners();

      // Check if we have a valid UUID
      final isServerUuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(_currentConversation!.id);

      // Build request body with empty messages array
      var body = {
        'content': content,
        'files': files,
        'assistant': {
          'id': _selectedModel!.id,
          'model': _selectedModel!.model,
          'name': _selectedModel!.name,
        },
        'metadata': {
          'conversation': {
            'messages': [], // Empty array for all requests
          },
        },
      };

      // Set up headers with the conversation ID for existing conversations
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Only add the header if it's a server UUID
      if (isServerUuid) {
        headers['x-jarvis-guid'] = _currentConversation!.id;
        print(
          "Including conversation ID in header: ${_currentConversation!.id}",
        );
      } else {
        print("First message - no conversation ID in header yet");
      }

      // Make the API request
      var url = Uri.parse('https://api.dev.jarvis.cx/api/v1/ai-chat/messages');

      print("Sending message with payload: ${json.encode(body)}");
      print("Headers: ${headers.toString()}");

      var response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Response data: $responseData");

        // Get the conversation ID from the response
        final newConversationId = responseData['conversationId'] ?? '';

        // Update our conversation ID with the one from the server (only for first message)
        if (newConversationId.isNotEmpty && !isServerUuid) {
          // Update the ID but don't change the reference
          _currentConversation!.id = newConversationId;
          print("Updated conversation ID to: $newConversationId");

          // Set title for new conversations
          if (_currentConversation!.title == 'New Conversation') {
            _currentConversation!.title =
                content.length > 30
                    ? '${content.substring(0, 27)}...'
                    : content;
          }

          // Update the conversations list reference if needed
          bool exists = false;
          for (int i = 0; i < _conversations.length; i++) {
            if (_conversations[i].id == _currentConversation!.id) {
              exists = true;
              break;
            }
          }

          if (!exists) {
            _conversations.insert(0, _currentConversation!);
          }

          notifyListeners();
        }

        // Update token usage if available
        if (responseData.containsKey('remainingUsage')) {
          _remainingUsage = responseData['remainingUsage'];
        }

        // Add AI response message
        final assistantMessage = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_response',
          content: responseData['message'] ?? 'No response',
          role: 'model',
          createdAt: DateTime.now(),
          assistant: AIAssistant(
            id: _selectedModel!.id,
            model: _selectedModel!.model,
            name: _selectedModel!.name,
          ),
        );

        _currentConversation!.messages.add(assistantMessage);
      } else {
        print("API error: ${response.statusCode} - ${response.body}");
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print('Error sending message: $e');

      // Show error in chat
      if (_currentConversation != null) {
        final errorMessage = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_error',
          content: 'Error: Failed to send message. Please try again.',
          role: 'system',
          createdAt: DateTime.now(),
          assistant: AIAssistant(
            id: _selectedModel!.id,
            model: _selectedModel!.model,
            name: 'System',
          ),
        );

        _currentConversation!.messages.add(errorMessage);
      }
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

  Future<void> sendMessageDirect(String token, String content) async {
    if (_selectedModel == null) return;
    if (content.trim().isEmpty) return;

    _isSendingMessage = true;
    notifyListeners();

    try {
      // Create user message and add to the conversation
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: 'user',
        createdAt: DateTime.now(),
        assistant: AIAssistant(
          id: _selectedModel!.id,
          model: _selectedModel!.model,
          name: _selectedModel!.name,
        ),
      );

      // Ensure we have a current conversation
      if (_currentConversation == null) {
        startNewConversation();
      }

      // Add the message to the current conversation
      _currentConversation!.messages.add(userMessage);
      notifyListeners();

      // Check if we have a valid UUID
      final isServerUuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(_currentConversation!.id);

      // Build the request
      var body = {
        'content': content,
        'files': [],
        'assistant': {
          'id': _selectedModel!.id,
          'model': _selectedModel!.model,
          'name': _selectedModel!.name,
        },
        'metadata': {
          'conversation': {
            'messages': [], // KEY CHANGE: Always use an empty array!
          },
        },
      };

      // Set up headers - put the conversation ID in x-jarvis-guid if it's a server UUID
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Only add the header if it's a server UUID
      if (isServerUuid) {
        headers['x-jarvis-guid'] = _currentConversation!.id;
        print(
          "Including conversation ID in header: ${_currentConversation!.id}",
        );
      } else {
        print("First message - no conversation ID in header yet");
      }

      // API request
      var url = Uri.parse('https://api.dev.jarvis.cx/api/v1/ai-chat/messages');

      print("Sending message with payload: ${json.encode(body)}");
      print("Headers: ${headers.toString()}");

      var response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Response data: $responseData");

        // Get the conversation ID from the response
        final newConversationId = responseData['conversationId'] ?? '';

        // Update our conversation ID with the one from the server (only for first message)
        if (newConversationId.isNotEmpty && !isServerUuid) {
          // Update the ID but don't change the reference
          _currentConversation!.id = newConversationId;
          print("Updated conversation ID to: $newConversationId");

          // Set title for new conversations (only on first message)
          if (_currentConversation!.title == 'New Conversation') {
            _currentConversation!.title =
                content.length > 30
                    ? '${content.substring(0, 27)}...'
                    : content;
          }

          // Update the conversations list reference
          bool exists = false;
          for (int i = 0; i < _conversations.length; i++) {
            if (_conversations[i].id == _currentConversation!.id) {
              exists = true;
              break;
            }
          }

          if (!exists) {
            _conversations.insert(0, _currentConversation!);
          }

          // Notify listeners
          notifyListeners();
        }

        // Update the token usage
        if (responseData.containsKey('remainingUsage')) {
          _remainingUsage = responseData['remainingUsage'];
        }

        // Add AI response message
        final assistantMessage = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_response',
          content: responseData['message'] ?? 'No response',
          role: 'model',
          createdAt: DateTime.now(),
          assistant: AIAssistant(
            id: _selectedModel!.id,
            model: _selectedModel!.model,
            name: _selectedModel!.name,
          ),
        );

        _currentConversation!.messages.add(assistantMessage);
      } else {
        print("API error: ${response.statusCode} - ${response.body}");
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in sendMessageDirect: $e");

      // Add error message to chat
      if (_currentConversation != null) {
        final errorMessage = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_error',
          content: 'Error: Failed to send message. Please try again.',
          role: 'system',
          createdAt: DateTime.now(),
          assistant: AIAssistant(
            id: _selectedModel?.id ?? 'system',
            model: _selectedModel?.model ?? 'system',
            name: 'System',
          ),
        );

        _currentConversation!.messages.add(errorMessage);
      }
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  // Helper function to check if a string is a valid UUID
  bool isUuid(String s) => RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(s);
}
