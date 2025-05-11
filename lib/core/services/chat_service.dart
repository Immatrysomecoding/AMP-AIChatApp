import 'dart:convert';
import 'package:aichat/core/models/EmailResponse.dart';
import 'package:http/http.dart' as http;
import 'package:aichat/core/models/ChatMessage.dart';
import 'package:aichat/core/models/AIModel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aichat/core/models/EmailRequest.dart';

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
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Format the messages in the expected structure
    List<Map<String, dynamic>> formattedMessages =
        previousMessages.map((msg) {
          return {
            'role': msg.role,
            'content': msg.content,
            'files': msg.files,
            'assistant': {
              'id': assistant.id,
              'model': assistant.model,
              'name': assistant.name,
            },
          };
        }).toList();

    // Build the request body according to the API spec
    var body = {
      'content': content,
      'files': files,
      'metadata': {
        'conversation': {'messages': formattedMessages},
      },
      'assistant': {
        'id': assistant.id,
        'model': assistant.model,
        'name': assistant.name,
      },
    };

    // Add conversationId if provided
    if (conversationId != null && conversationId.isNotEmpty) {
      body['conversationId'] = conversationId;
    }

    print("Sending request body: ${json.encode(body)}");

    try {
      var url = Uri.parse('$baseUrl/api/v1/ai-chat/messages');

      var response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extract the relevant data from the response
        return {
          'conversationId': responseData['conversationId'] ?? '',
          'message': responseData['answer'] ?? responseData['message'] ?? '',
          'remainingUsage': responseData['remainingUsage'] ?? 0,
        };
      } else {
        print("API error: ${response.statusCode} - ${response.body}");
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Network error in sendMessage: $e");
      throw e;
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

  Future<EmailResponse> generateResponseEmail(
    String token,
    EmailRequest model,
  ) async {
    final headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final requestBody = {
      'mainIdea': model.mainIdea,
      'action': model.action,
      'email': model.email,
      'metadata': {
        'context': model.metadata.context,
        'subject': model.metadata.subject,
        'sender': model.metadata.sender,
        'receiver': model.metadata.receiver,
        'language': model.metadata.language,
        if (model.metadata.style != null)
          'style': {
            'length': model.metadata.style!.length,
            'formality': model.metadata.style!.formality,
            'tone': model.metadata.style!.tone,
          },
      },
    };

    final request = http.Request('POST', Uri.parse('$baseUrl/api/v1/ai-email'));
    request.headers.addAll(headers);
    request.body = json.encode(requestBody);

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final responseData = json.decode(responseBody);
      print("Response data: $responseData");
      return EmailResponse.fromJson(responseData);
    } else {
      throw Exception('Failed: $responseBody');
    }
  }

  Future<EmailResponse> replyEmailIdeas(
    String token,
    EmailRequest model,
  ) async {
    final headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final requestBody = {
      "assistant": {
        "id": "gpt-4o-mini",
        "model": "dify",
        "name": "gpt-4o-mini",
      },
      'mainIdea': model.mainIdea,
      'action': model.action,
      'email': model.email,
      'metadata': {
        'context': model.metadata.context,
        'subject': model.metadata.subject,
        'sender': model.metadata.sender,
        'receiver': model.metadata.receiver,
        'language': model.metadata.language,
      },
    };

    final request = http.Request('POST', Uri.parse('$baseUrl/api/v1/ai-email'));
    request.headers.addAll(headers);
    request.body = json.encode(requestBody);

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('✅ Response received:\n$responseBody');
        final responseData = json.decode(responseBody);
        return EmailResponse.fromJson(responseData);
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        print('Reason: ${response.reasonPhrase}');
        print('Response body: ${await response.stream.bytesToString()}');
        throw Exception('Failed to send request: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('⚠️ Error occurred while sending request: $e');
      throw Exception('Failed to send reply email ideas: $e');
    }
  }
}
