import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aichat/core/models/ChatMessage.dart';
import 'package:aichat/core/models/AIModel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  final String baseUrl = dotenv.env['CHAT_URL'] ?? '';

  Map<String, String> buildHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'x-jarvis-guid': '',
    'X-Stack-Access-Type': dotenv.env['STACK_ACCESS_KEY'] ?? '',
    'X-Stack-Project-Id': dotenv.env['STACK_PROJECT_ID'] ?? '',
    'X-Stack-Publishable-Client-Key': dotenv.env['STACK_CLIENT_KEY'] ?? '',
    'Content-Type': 'application/json',
  };

  // Mock AI model list
  Future<List<AIModel>> getAvailableModels(String token) async {
    // Add a small delay to simulate network request
    await Future.delayed(const Duration(milliseconds: 300));

    List<Map<String, dynamic>> mockModels = [
      {
        'id': 'gpt-4o-mini',
        'model': 'dify',
        'name': 'GPT-4o mini',
        'description': 'Fast and efficient AI model for everyday tasks.',
        'isDefault': true,
      },
      {
        'id': 'gpt-4o',
        'model': 'dify',
        'name': 'GPT-4o',
        'description': 'Powerful AI model for complex tasks.',
      },
      {
        'id': 'gemini-1.5-flash-latest',
        'model': 'dify',
        'name': 'Gemini 1.5 Flash',
        'description': 'Google\'s advanced AI model.',
      },
      {
        'id': 'gemini-1.5-pro',
        'model': 'dify',
        'name': 'Gemini 1.5 Pro',
        'description': 'Google\'s most powerful AI model.',
      },
      {
        'id': 'claude-3-haiku',
        'model': 'dify',
        'name': 'Claude 3 Haiku',
        'description': 'Anthropic\'s fast AI assistant model.',
      },
      {
        'id': 'claude-3.5-sonnet',
        'model': 'dify',
        'name': 'Claude 3.5 Sonnet',
        'description': 'Anthropic\'s most capable AI assistant.',
      },
      {
        'id': 'deepseek-chat',
        'model': 'dify',
        'name': 'Deepseek Chat',
        'description': 'Deepseek\'s conversational AI model.',
      },
      {
        'id': 'bot_jarvis',
        'model': 'knowledge-base',
        'name': 'Jarvis Bot',
        'description': 'Your custom assistant bot.',
      },
    ];

    return mockModels.map((model) => AIModel.fromJson(model)).toList();
  }

  // Fetch conversation list with error handling
  Future<List<Conversation>> getConversations(
    String token,
    String assistantId,
    String assistantModel,
  ) async {
    try {
      var headers = buildHeaders(token);
      var url = Uri.parse(
        '$baseUrl/api/v1/ai-chat/conversations?assistantId=$assistantId&assistantModel=$assistantModel',
      );

      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        List<dynamic> items = responseData['items'] ?? [];

        return items.map((item) {
          item['assistant'] = {
            'id': assistantId,
            'model': assistantModel,
            'name': '',
          };
          return Conversation.fromJson(item);
        }).toList();
      } else {
        print("❌ Failed to load conversations from ${url.path}");
        print("Status: ${response.statusCode}");
        print("Response: ${response.body}");

        // Return empty list instead of throwing
        return [];
      }
    } catch (e) {
      print("⚠️ Exception when loading conversations: $e");
      // Return empty list on error
      return [];
    }
  }

  // Fetch conversation messages with improved error handling
  Future<List<ChatMessage>> getConversationMessages(
    String token,
    String conversationId,
    String assistantId,
    String assistantModel,
  ) async {
    try {
      var headers = buildHeaders(token);
      var url = Uri.parse(
        '$baseUrl/api/v1/ai-chat/conversations/$conversationId/messages?assistantId=$assistantId&assistantModel=$assistantModel',
      );

      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        List<dynamic> items = responseData['items'] ?? [];
        List<ChatMessage> messages = [];

        for (var item in items) {
          var userMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: item['query'] ?? '',
            role: 'user',
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (item['createdAt'] ??
                      (DateTime.now().millisecondsSinceEpoch ~/ 1000)) *
                  1000,
            ),
            files:
                item['files'] != null ? List<String>.from(item['files']) : [],
            assistant: AIAssistant(
              id: assistantId,
              model: assistantModel,
              name: '',
            ),
          );

          var assistantMessage = ChatMessage(
            id: "${DateTime.now().millisecondsSinceEpoch}_response",
            content: item['answer'] ?? 'No response available',
            role: 'model',
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (item['createdAt'] ??
                          (DateTime.now().millisecondsSinceEpoch ~/ 1000)) *
                      1000 +
                  1,
            ),
            files: [],
            assistant: AIAssistant(
              id: assistantId,
              model: assistantModel,
              name: '',
            ),
          );

          messages.add(userMessage);
          messages.add(assistantMessage);
        }

        return messages;
      } else {
        print("❌ Failed to load messages for conversation $conversationId");
        print("Status: ${response.statusCode}");
        print("Response: ${response.body}");

        // Return empty list instead of throwing
        return [];
      }
    } catch (e) {
      print("⚠️ Exception when loading messages: $e");
      // Return empty list on error
      return [];
    }
  }

  // Send message with improved error handling
  Future<Map<String, dynamic>> sendMessage(
    String token,
    String content,
    List<String> files,
    AIAssistant assistant,
    List<ChatMessage> previousMessages, [
    String? conversationId,
  ]) async {
    var headers = buildHeaders(token);

    // Format previous messages
    List<Map<String, dynamic>> formattedMessages =
        previousMessages
            .map(
              (m) => {
                'role': m.role,
                'content': m.content,
                'files': m.files,
                'assistant': m.assistant.toJson(),
              },
            )
            .toList();

    var body = {
      'content': content,
      'files': files,
      'metadata': {
        'conversation': {'messages': formattedMessages},
      },
      'assistant': assistant.toJson(),
    };

    if (conversationId != null) {
      body['conversationId'] = conversationId;
    }

    try {
      var url = Uri.parse('$baseUrl/api/v1/ai-chat/messages');
      var response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("❌ Failed to send message to ${url.path}");
        print("Status: ${response.statusCode}");
        print("Response: ${response.body}");

        // Return a mock response instead of throwing to prevent UI flashes
        // This will show an error message in the UI but prevent crashes
        return {
          'conversationId':
              conversationId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          'message': 'Server error occurred. Please try again later.',
          'remainingUsage': 0,
        };
      }
    } catch (e) {
      print("⚠️ Network exception when sending message: $e");

      // Return a mock response for offline situations
      return {
        'conversationId':
            conversationId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'message': 'Network error. Please check your connection.',
        'remainingUsage': 0,
      };
    }
  }

  // Mock response for when the server is down
  Map<String, dynamic> _createMockResponse(String? conversationId) {
    return {
      'conversationId':
          conversationId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'message':
          'This is a mock response because the server is currently unavailable.',
      'remainingUsage': 10,
    };
  }
}
