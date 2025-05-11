import 'package:aichat/core/models/EmailRequest.dart';
import 'package:aichat/core/models/EmailResponse.dart';
import 'package:flutter/material.dart';
import 'package:aichat/core/models/ChatMessage.dart';
import 'package:aichat/core/models/AIModel.dart';
import 'package:aichat/core/services/chat_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

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
      // Continue anyway for debugging
    }

    _setLoading(true);

    try {
      print("Fetching conversations with token length: ${token.length}");

      // Hardcode for testing
      var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};

      var url = Uri.parse(
        'https://api.dev.jarvis.cx/api/v1/ai-chat/conversations?assistantId=gpt-4o-mini&assistantModel=dify',
      );
      print("Fetching from URL: ${url.toString()}");

      var request = http.Request('GET', url);
      request.headers.addAll(headers);

      var response = await request.send();

      print("Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print("Response body length: ${responseBody.length} characters");

        final decoded = json.decode(responseBody);
        List<dynamic> items = decoded['items'] ?? [];

        print("Found ${items.length} conversations in API response");

        List<Conversation> newConversations = [];

        for (var item in items) {
          try {
            // Add assistant info to each conversation for compatibility
            item['assistant'] = {
              'id': _selectedModel?.id ?? 'gpt-4o-mini',
              'model': _selectedModel?.model ?? 'dify',
              'name': _selectedModel?.name ?? 'GPT-4o mini',
            };

            Conversation conv = Conversation.fromJson(item);
            print(
              "Successfully parsed conversation: ${conv.id} - ${conv.title}",
            );
            newConversations.add(conv);
          } catch (e) {
            print("Error parsing conversation item: $e");
            print("Problematic item: $item");
          }
        }

        // Update the conversations list
        _conversations = newConversations;

        // Sort conversations by date (newest first)
        _conversations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print("Updated provider with ${_conversations.length} conversations");
      } else {
        print(
          'Error fetching conversations: ${response.statusCode} - ${response.reasonPhrase}',
        );
        _conversations = [];
      }
    } catch (e) {
      print('Exception in fetchConversations: $e');
      _conversations = [];
    } finally {
      _setLoading(false);
      notifyListeners(); // Make sure UI updates
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
    notifyListeners(); // Notify before starting so UI shows loading state

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

      print(
        "Loading messages for conversation: ${existingConversation.id} - ${existingConversation.title}",
      );

      // Fetch the messages directly using http
      var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};

      // Use dynamic assistantId/model values from the current model
      var url = Uri.parse(
        'https://api.dev.jarvis.cx/api/v1/ai-chat/conversations/$conversationId/messages?assistantId=${_selectedModel!.id}&assistantModel=${_selectedModel!.model}',
      );

      print("Fetching messages from URL: $url");
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print("Received message data of ${responseBody.length} bytes");

        var responseData = json.decode(responseBody);
        List<dynamic> items = responseData['items'] ?? [];

        print("Found ${items.length} messages in API response");

        List<ChatMessage> messages = [];

        // Process each message in the response
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

        print("Processed ${messages.length} messages successfully");

        // Update the conversation with the messages
        existingConversation.messages = messages;
        existingConversation.title =
            existingConversation.title == 'Loading...' && items.isNotEmpty
                ? (items[0]['query'] ?? 'Conversation').substring(
                  0,
                  min(20, (items[0]['query'] ?? 'Conversation').length),
                )
                : existingConversation.title;

        _currentConversation = existingConversation;
        print(
          "Successfully loaded conversation with ${messages.length} messages",
        );
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
      notifyListeners(); // Update UI after loading completes
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
      messages: [], // Ensure messages is an empty list
    );

    notifyListeners();
  }

  void setCurrentConversationWithMessages(Conversation conversation) {
    _currentConversation = conversation;
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

    // Start a new conversation if none is active
    if (_currentConversation == null) {
      startNewConversation();
    }

    // Create a user message with the correct assistant info
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

    _currentConversation!.messages.add(userMessage);
    notifyListeners();

    try {
      // Important: Pass the existing conversation ID if available
      final String? conversationId =
          _currentConversation!.id.isNotEmpty ? _currentConversation!.id : null;
      print(
        "Sending message to conversation ID: ${conversationId ?? 'NEW CONVERSATION'}",
      );

      var response = await _chatService.sendMessage(
        token,
        content,
        files,
        AIAssistant(
          id: _selectedModel!.id,
          model: _selectedModel!.model,
          name: _selectedModel!.name,
        ),
        _currentConversation!.messages,
        conversationId,
      );

      // Update remaining usage
      if (response.containsKey('remainingUsage')) {
        _remainingUsage = response['remainingUsage'];
      }

      // Update conversation ID if this is a new conversation
      if (_currentConversation!.id.isEmpty &&
          response.containsKey('conversationId')) {
        _currentConversation!.id = response['conversationId'];
        print("Received new conversation ID: ${_currentConversation!.id}");

        // Set the title to the first message content (shortened if needed)
        _currentConversation!.title =
            content.length > 30 ? '${content.substring(0, 27)}...' : content;

        // Add this conversation to our list
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
            id: _selectedModel!.id,
            model: _selectedModel!.model,
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
          id: _selectedModel!.id,
          model: _selectedModel!.model,
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

  // Add this method to the ChatProvider class
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

      if (_currentConversation == null) {
        startNewConversation();
      }

      _currentConversation!.messages.add(userMessage);
      notifyListeners();

      // Format previous messages
      List<Map<String, dynamic>> formattedMessages =
          _currentConversation!.messages.map((msg) {
            return {
              'role': msg.role,
              'content': msg.content,
              'files': msg.files ?? [],
              'assistant': {
                'id': _selectedModel!.id,
                'model': _selectedModel!.model,
                'name': _selectedModel!.name,
              },
            };
          }).toList();

      // Build request body
      var body = {
        'content': content,
        'files': [],
        'metadata': {
          'conversation': {'messages': formattedMessages},
        },
        'assistant': {
          'id': _selectedModel!.id,
          'model': _selectedModel!.model,
          'name': _selectedModel!.name,
        },
      };

      // Add conversation ID if available
      if (_currentConversation!.id.isNotEmpty) {
        body['conversationId'] = _currentConversation!.id;
      }

      // Make the API request directly
      var url = Uri.parse('https://api.dev.jarvis.cx/api/v1/ai-chat/messages');
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      print("Sending direct message request");
      var response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Response data: $responseData");

        // Update conversation ID if needed
        if (_currentConversation!.id.isEmpty &&
            responseData.containsKey('conversationId')) {
          _currentConversation!.id = responseData['conversationId'];

          // Add to conversations list if new
          bool exists = _conversations.any(
            (conv) => conv.id == _currentConversation!.id,
          );
          if (!exists) {
            _conversations.insert(0, _currentConversation!);
          }
        }

        // Add AI response message
        final assistantMessage = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_response',
          content:
              responseData['answer'] ??
              responseData['message'] ??
              'No response',
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
}
