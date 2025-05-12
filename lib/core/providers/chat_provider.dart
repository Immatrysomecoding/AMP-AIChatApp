import 'package:aichat/core/models/EmailRequest.dart';
import 'package:aichat/core/models/EmailResponse.dart';
import 'package:flutter/material.dart';
import 'package:aichat/core/models/ChatMessage.dart';
import 'package:aichat/core/models/AIModel.dart';
import 'package:aichat/core/services/chat_service.dart';
import 'package:aichat/core/services/bot_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final BotService _botService = BotService();

  List<AIModel> _availableModels = [];
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  AIModel? _selectedModel;
  bool _isLoading = false;
  int _remainingUsage = 50;
  bool _isSendingMessage = false;
  bool _isSelectedModelBot = false;
  String? _botId;
  String? _botThreadId; // Track bot thread ID separately
  String? _botConversationId; // Track the actual conversation ID from the API

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

  Future<void> setSelectedModel(AIModel model, String token) async {
    try {
      final String? currentConversationId = _currentConversation?.id;

      // Clear current conversation before switching model
      _currentConversation = null;
      _botThreadId = null; // Clear bot thread ID
      _botConversationId = null; // Clear bot conversation ID

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
      notifyListeners();
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

      // Check if this is a bot conversation
      if (_isSelectedModelBot && _botId != null) {
        await _sendBotMessage(token, content);
      } else {
        await _sendRegularMessage(token, content);
      }
    } catch (e) {
      print("Error in sendMessageDirect: $e");
      _handleSendError(e);
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  Future<void> _sendBotMessage(String token, String content) async {
    try {
      Map<String, dynamic>? response;

      // For bots, we need to handle the thread creation differently
      if (_botConversationId == null || _botConversationId!.isEmpty) {
        // First message - create a new thread
        print("Creating new bot thread for bot: $_botId");
        final threadResponse = await _botService.createThreadForBot(
          token,
          _botId!,
          content,
        );

        if (threadResponse != null) {
          _botConversationId = threadResponse['openAiThreadId'] ?? '';
          // The first response is already included in createThreadForBot
          response = threadResponse;
          print(
            "Created bot thread: $_botConversationId with message: ${response['message']}",
          );
        } else {
          throw Exception("Failed to create bot thread");
        }
      } else {
        // Subsequent messages - use existing conversation ID
        print(
          "Sending message to existing bot conversation: $_botConversationId",
        );
        response = await _botService.askBot(
          token,
          _botId!,
          content,
          _botConversationId!,
          "", // Additional instructions
          onChunkReceived: (chunk) {
            // Handle streaming response if needed
            print("Received chunk: $chunk");
          },
        );
      }

      if (response != null && response.containsKey('message')) {
        // Update conversation ID if provided in response
        if (response.containsKey('openAiThreadId') &&
            response['openAiThreadId'] != null) {
          _botConversationId = response['openAiThreadId'];
        }

        // Add bot response message
        final assistantMessage = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_response',
          content: response['message'] ?? 'No response',
          role: 'model',
          createdAt: DateTime.now(),
          assistant: AIAssistant(
            id: _selectedModel!.id,
            model: _selectedModel!.model,
            name: _selectedModel!.name,
          ),
        );

        _currentConversation!.messages.add(assistantMessage);
        notifyListeners();

        // For bot conversations, keep the temporary ID to ensure they remain temporary
        // Don't update the conversation ID or add to history
        if (_currentConversation!.id.startsWith('temp-')) {
          // Update title but keep the temp ID
          if (_currentConversation!.title == 'New Conversation') {
            _currentConversation!.title =
                content.length > 30
                    ? '${content.substring(0, 27)}...'
                    : content;
          }
        }
      } else {
        throw Exception("Invalid bot response");
      }
    } catch (e) {
      print("Error in _sendBotMessage: $e");
      throw e;
    }
  }

  Future<void> _sendRegularMessage(String token, String content) async {
    // Existing code for regular AI models
    final isServerUuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(_currentConversation!.id);

    // Prepare the conversation messages in the format the server expects
    List<Map<String, dynamic>> conversationMessages = [];
    for (var message in _currentConversation!.messages) {
      conversationMessages.add({
        'role': message.role,
        'content': message.content,
        'assistant': {
          'id': message.assistant.id,
          'model': message.assistant.model,
          'name': message.assistant.name,
        },
      });
    }

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
          if (isServerUuid) 'id': _currentConversation!.id,
          'messages': conversationMessages,
        },
      },
    };

    if (isServerUuid) {
      body['conversationId'] = _currentConversation!.id;
    }

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    if (isServerUuid) {
      headers['x-jarvis-guid'] = _currentConversation!.id;
    }

    var url = Uri.parse('https://api.dev.jarvis.cx/api/v1/ai-chat/messages');

    print("Sending message with payload: ${json.encode(body)}");

    var response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // Get the conversation ID from the response
      final newConversationId = responseData['conversationId'] ?? '';

      // Update our conversation ID with the one from the server (only for first message)
      if (newConversationId.isNotEmpty && !isServerUuid) {
        _currentConversation!.id = newConversationId;

        // Set title for new conversations
        if (_currentConversation!.title == 'New Conversation') {
          _currentConversation!.title =
              content.length > 30 ? '${content.substring(0, 27)}...' : content;
        }

        // Update the conversations list
        bool exists = _conversations.any(
          (conv) => conv.id == _currentConversation!.id,
        );
        if (!exists) {
          _conversations.insert(0, _currentConversation!);
        }

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
  }

  void _handleSendError(dynamic error) {
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
  }

  void startNewConversation() {
    if (_selectedModel == null) return;

    _currentConversation = Conversation(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Conversation',
      createdAt: DateTime.now(),
      assistant: AIAssistant(
        id: _selectedModel!.id,
        model: _selectedModel!.model,
        name: _selectedModel!.name,
      ),
      messages: [],
    );

    // Clear bot thread ID for new conversations
    _botThreadId = null;
    _botConversationId = null;

    // Only add to conversations list if it's not a bot
    if (!_isSelectedModelBot) {
      _conversations.insert(0, _currentConversation!);
    }

    notifyListeners();
  }

  // Existing methods remain unchanged...
  Future<void> fetchConversations(String token) async {
    if (_selectedModel == null) {
      print("WARNING: No model selected in fetchConversations");
    }

    _setLoading(true);

    try {
      // Don't fetch conversations for bot models
      if (_isSelectedModelBot) {
        _conversations = [];
        return;
      }

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

        // If we have a current conversation that's not in the API list and it's not a bot, keep it
        if (_currentConversation != null && !_isSelectedModelBot) {
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadConversation(String token, String conversationId) async {
    if (_selectedModel == null) {
      print("Warning: No model selected in loadConversation");
      // Set a default model if none is selected
      _selectedModel = _availableModels.firstWhere(
        (model) => model.id == 'gpt-4o-mini',
        orElse:
            () => AIModel(
              id: 'gpt-4o-mini',
              model: 'dify',
              name: 'GPT-4o mini',
              isDefault: true,
            ),
      );
    }

    _setLoading(true);
    notifyListeners();

    try {
      // Check if we already have this conversation loaded
      Conversation? existingConversation;
      try {
        existingConversation = _conversations.firstWhere(
          (conv) => conv.id == conversationId,
        );
      } catch (e) {
        // Conversation not found, create a temporary one
        existingConversation = Conversation(
          id: conversationId,
          title: 'Loading...',
          createdAt: DateTime.now(),
          assistant: AIAssistant(
            id: _selectedModel!.id,
            model: _selectedModel!.model,
            name: _selectedModel!.name,
          ),
        );
      }

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
            // Parse the date safely
            DateTime createdAt;
            try {
              // Check if createdAt is a string or an int
              if (item['createdAt'] is String) {
                createdAt = DateTime.parse(item['createdAt']);
              } else if (item['createdAt'] is int) {
                createdAt = DateTime.fromMillisecondsSinceEpoch(
                  item['createdAt'] * 1000,
                );
              } else {
                // Default to current time if date is invalid
                createdAt = DateTime.now();
              }
            } catch (e) {
              print("Date parsing error for message: $e");
              createdAt = DateTime.now();
            }

            // User message
            var userMessage = ChatMessage(
              id: "${item['id'] ?? DateTime.now().millisecondsSinceEpoch}_user",
              content: item['query'] ?? '',
              role: 'user',
              createdAt: createdAt,
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
              createdAt: createdAt.add(Duration(milliseconds: 1)),
              assistant: AIAssistant(
                id: _selectedModel!.id,
                model: _selectedModel!.model,
                name: _selectedModel!.name,
              ),
            );

            messages.add(userMessage);
            messages.add(aiMessage);

            print(
              "Added messages: User='${userMessage.content}', AI='${aiMessage.content}'",
            );
          } catch (e) {
            print("Error processing message: $e");
            print("Message data: ${json.encode(item)}");
          }
        }

        // Update the conversation with the messages
        existingConversation.messages = messages;
        existingConversation.title =
            existingConversation.title == 'Loading...' && items.isNotEmpty
                ? (items[0]['query'] ?? 'Conversation').toString().length > 20
                    ? "${items[0]['query'].toString().substring(0, 20)}..."
                    : items[0]['query'].toString()
                : existingConversation.title;

        // Set as current conversation
        _currentConversation = existingConversation;

        // Make sure it's in our conversations list
        final conversationToCheck = existingConversation;
        bool exists = _conversations.any(
          (conv) => conv.id == conversationToCheck.id,
        );
        if (!exists) {
          _conversations.insert(0, existingConversation);
        }

        // Clear any "New Conversation" entries
        _conversations.removeWhere((conv) => conv.id.startsWith('temp-'));

        print("Loaded ${messages.length} messages for conversation");
      } else {
        print(
          "Error loading messages: ${response.statusCode} - ${response.reasonPhrase}",
        );
        print("Response body: ${response.body}");
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

  // Other existing methods...
  void updateConversations(List<Conversation> conversations) {
    _conversations = conversations;
    notifyListeners();
  }

  Future<void> deleteConversation(String token, String conversationId) async {
    try {
      _conversations.removeWhere((conv) => conv.id == conversationId);

      if (_currentConversation != null &&
          _currentConversation!.id == conversationId) {
        _currentConversation = null;
      }

      notifyListeners();
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  Future<EmailResponse> generateResponseEmail(
    String token,
    EmailRequest emailRequest,
  ) async {
    return await _chatService.generateResponseEmail(token, emailRequest);
  }

  Future<EmailResponse> replyEmailIdeas(
    String token,
    EmailRequest emailRequest,
  ) async {
    return await _chatService.replyEmailIdeas(token, emailRequest);
  }

  // Helper function to check if a string is a valid UUID
  bool isUuid(String s) => RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(s);
}
