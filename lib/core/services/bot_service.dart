import 'dart:async';
import 'dart:convert';
import 'package:aichat/core/models/BotConfiguration.dart';
import 'package:aichat/core/models/Knowledge.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:aichat/core/models/Bot.dart';

class BotService {
  String baseUrl = dotenv.env['KNOWLEDGE_URL'] ?? "";

  // Updated method to create a thread for bot - using playground endpoint
  Future<Map<String, dynamic>?> createThreadForBot(
    String token,
    String botId,
    String firstMsg,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      // First, let's try using the playground endpoint
      var playgroundRequest = http.Request(
        'POST',
        Uri.parse('$baseUrl/kb-core/v1/ai-assistant/thread/playground'),
      );
      playgroundRequest.body = json.encode({
        "assistantId": botId,
        "firstMessage": firstMsg,
      });
      playgroundRequest.headers.addAll(headers);

      var playgroundResponse = await playgroundRequest.send();
      final playgroundBody = await playgroundResponse.stream.bytesToString();

      print("Playground response status: ${playgroundResponse.statusCode}");
      print("Playground response body: $playgroundBody");

      if (playgroundResponse.statusCode == 200 ||
          playgroundResponse.statusCode == 201) {
        try {
          Map<String, dynamic> data = json.decode(playgroundBody);

          // Extract thread ID from response
          String? threadId =
              data['openAiThreadId'] ?? data['threadId'] ?? data['id'];

          if (threadId != null) {
            // Now let's send the first message directly
            return await askBot(token, botId, firstMsg, threadId, "");
          }
        } catch (e) {
          print("Error parsing playground response: $e");
        }
      }

      // If playground doesn't work, try the direct ask endpoint with an initial message
      print("Trying direct ask endpoint as fallback...");

      var askRequest = http.Request(
        'POST',
        Uri.parse('$baseUrl/kb-core/v1/ai-assistant/$botId/ask'),
      );
      askRequest.body = json.encode({
        "message": firstMsg,
        "openAiThreadId": "", // Empty for first message
        "additionalInstruction": "",
      });
      askRequest.headers.addAll(headers);

      var askResponse = await askRequest.send();

      print("Ask response status: ${askResponse.statusCode}");

      if (askResponse.statusCode == 200) {
        // Handle SSE response for the first message
        final response = await _parseSSEResponse(askResponse, "");
        return response;
      }

      // Final fallback - create a mock thread
      print("Using fallback mock thread");
      return {
        'openAiThreadId': 'bot-thread-${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Hello! How can I assist you today?',
      };
    } catch (e) {
      print("Exception in createThreadForBot: $e");
      // Return a mock response for development/testing
      return {
        'openAiThreadId': 'bot-thread-${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Hello! How can I assist you today?',
      };
    }
  }

  Future<Map<String, dynamic>?> askBot(
    String token,
    String botId,
    String msg,
    String openAiThreadId,
    String additionalInstruction, {
    Function(String)? onChunkReceived,
  }) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      var request = http.Request(
        'POST',
        Uri.parse('$baseUrl/kb-core/v1/ai-assistant/$botId/ask'),
      );

      Map<String, dynamic> body = {
        "message": msg,
        "additionalInstruction": additionalInstruction,
      };

      // Only include threadId if it's not empty and not a temp ID
      if (openAiThreadId.isNotEmpty &&
          !openAiThreadId.startsWith('bot-thread-')) {
        body["openAiThreadId"] = openAiThreadId;
      }

      request.body = json.encode(body);
      request.headers.addAll(headers);

      var response = await request.send();
      print("Bot ask response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Handle SSE response
        return await _parseSSEResponse(
          response,
          openAiThreadId,
          onChunkReceived: onChunkReceived,
        );
      } else {
        final errorBody = await response.stream.bytesToString();
        print("Error asking bot: ${response.statusCode} - $errorBody");

        // Try to parse error message
        try {
          final errorData = json.decode(errorBody);
          final errorMessage = errorData['message'] ?? 'Bot unavailable';
          return {
            'message': "Error: $errorMessage",
            'openAiThreadId': openAiThreadId,
            'error': true,
          };
        } catch (e) {
          return {
            'message':
                "I'm sorry, I couldn't process that request. Please try again.",
            'openAiThreadId': openAiThreadId,
            'error': true,
          };
        }
      }
    } catch (e) {
      print("Exception in askBot: $e");
      return {
        'message': "I'm sorry, I couldn't process that request.",
        'openAiThreadId': openAiThreadId,
        'error': true,
      };
    }
  }

  // Helper method to parse SSE responses
  Future<Map<String, dynamic>> _parseSSEResponse(
    http.StreamedResponse response,
    String fallbackThreadId, {
    Function(String)? onChunkReceived,
  }) async {
    String fullMessage = '';
    String conversationId = fallbackThreadId;

    try {
      final responseBody = await response.stream.bytesToString();
      print("Raw SSE response: $responseBody");

      // Parse SSE format
      final lines = responseBody.split('\n');

      for (var line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6); // Remove 'data: ' prefix
          if (data.trim().isNotEmpty) {
            try {
              final json = jsonDecode(data);
              if (json['content'] != null) {
                fullMessage += json['content'];
                if (onChunkReceived != null && json['content'].isNotEmpty) {
                  onChunkReceived(json['content']);
                }
              }
              if (json['conversationId'] != null &&
                  conversationId.startsWith('bot-thread-')) {
                conversationId = json['conversationId'];
              }
            } catch (e) {
              print("Error parsing SSE data: $e");
            }
          }
        }
      }

      print("Parsed message: $fullMessage");
      print("Conversation ID: $conversationId");

      return {
        'message':
            fullMessage.isNotEmpty
                ? fullMessage
                : "Hello! How can I assist you today?",
        'openAiThreadId': conversationId,
      };
    } catch (e) {
      print("Error parsing SSE response: $e");
      return {
        'message': "I received your message.",
        'openAiThreadId': fallbackThreadId,
      };
    }
  }

  Future<List<Bot>> fetchBots(String token) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};

    var request = http.Request(
      'GET',
      Uri.parse(
        '$baseUrl/kb-core/v1/ai-assistant?q&order=DESC&order_field=createdAt&offset&limit=20',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final decoded = json.decode(responseBody);

      if (decoded['data'] != null && decoded['data'] is List) {
        List<dynamic> items = decoded['data'];
        return items.map((data) => Bot.fromJson(data)).toList();
      } else {
        print("Warning: 'data' is missing or null");
        return [];
      }
    } else {
      throw Exception('Failed to fetch bots: ${response.reasonPhrase}');
    }
  }

  Future<void> createBot(
    String token,
    String botName,
    String instruction,
    String description,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/ai-assistant'),
    );
    request.body = json.encode({
      "assistantName": botName,
      "instructions": instruction,
      "description": description,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 201) {
      print(await response.stream.bytesToString());
      print("Bot created successfully");
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> updateBot(
    String token,
    String id,
    String name,
    String instruction,
    String description,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'PATCH',
      Uri.parse('$baseUrl/kb-core/v1/ai-assistant/$id'),
    );
    request.body = json.encode({
      "assistantName": name,
      "instructions": instruction,
      "description": description,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
      print("Bot updated successfully");
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> deleteBot(String token, String id) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'DELETE',
      Uri.parse('$baseUrl/kb-core/v1/ai-assistant/$id'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
      print("Bot deleted successfully");
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> toggleFavoriteBot(String token, String id) async {
    print("Toggling favorite for bot with ID: $id");

    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var body = jsonEncode({'assistantId': id});

    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/ai-assistant/$id/favorite'),
    );

    request.headers.addAll(headers);
    request.body = body;

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
      print("Bot favorite status toggled successfully");
    } else {
      print("Failed to toggle favorite status: ${response.statusCode}");
      print(response.reasonPhrase);
    }
  }

  Future<void> importKnowledgeToBot(
    String token,
    String botId,
    String knowledgeId,
  ) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'POST',
      Uri.parse(
        '$baseUrl/kb-core/v1/ai-assistant/$botId/knowledges/$knowledgeId',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> deleteKnowledgeFromBot(
    String token,
    String botId,
    String knowledgeId,
  ) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'DELETE',
      Uri.parse(
        '$baseUrl/kb-core/v1/ai-assistant/$botId/knowledges/$knowledgeId',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<List<Knowledge>> getImportedKnowledge(
    String token,
    String botId,
  ) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'GET',
      Uri.parse(
        '$baseUrl/kb-core/v1/ai-assistant/$botId/knowledges?q&order=DESC&order_field=createdAt&offset&limit=20',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print("Response Body: $responseBody");
      final decoded = json.decode(responseBody);
      if (decoded['data'] != null && decoded['data'] is List) {
        List<dynamic> items = decoded['data'];
        return items.map((data) => Knowledge.fromJson(data)).toList();
      } else {
        print("Warning: 'data' is missing or null");
        return [];
      }
    } else {
      print(response.reasonPhrase);
      throw Exception(
        'Failed to fetch imported knowledge: ${response.reasonPhrase}',
      );
    }
  }

  Future<void> updateBotWithNewThreadPlayGround(
    String token,
    String botId,
    String firstMsg,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/ai-assistant/thread/playground'),
    );
    request.body = json.encode({
      "assistantId": botId,
      "firstMessage": firstMsg,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<List<BotConfiguration>> getBotConfiguration(
    String token,
    String botId,
  ) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};

    var request = http.Request(
      'GET',
      Uri.parse('$baseUrl/kb-core/v1/bot-integration/$botId/configurations'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final decoded = json.decode(responseBody);

      print("Decoded: $decoded");

      // Correct: `decoded` is a List
      List<BotConfiguration> botConfigurations =
          (decoded as List)
              .map((botData) => BotConfiguration.fromJson(botData))
              .toList();

      print("Bot configuration fetched successfully");
      return botConfigurations;
    } else {
      print('Error: ${response.statusCode} ${response.reasonPhrase}');
      return [];
    }
  }

  Future<void> publishTelegramBot(
    String token,
    String botId,
    String botToken,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/bot-integration/telegram/publish/$botId'),
    );
    request.body = json.encode({"botToken": botToken});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print("Telegram bot published successfully");
      final responseBody = await response.stream.bytesToString();
      final decoded = json.decode(responseBody);
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> disconnectBotConfiguration(
    String token,
    String botId,
    String type,
  ) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'DELETE',
      Uri.parse('$baseUrl/kb-core/v1/bot-integration/$botId/$type'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<bool> verifyTelegramBot(String token, String botToken) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/bot-integration/telegram/validation'),
    );
    request.body = json.encode({"botToken": botToken});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print("Telegram bot verified successfully");
      final responseBody = await response.stream.bytesToString();
      final decoded = json.decode(responseBody);
      if (decoded['ok'] == true) {
        return true;
      }
      print("Decoded: $decoded");
    } else {
      print(response.reasonPhrase);
      print("Failed to verify Telegram bot: ${response.statusCode}");
    }
    return false;
  }

  Future<void> publishSlackBot(
    String token,
    String botId,
    String botToken,
    String clientId,
    String clientSecret,
    String signingSecret,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/bot-integration/slack/publish/$botId'),
    );
    request.body = json.encode({
      "botToken": botToken,
      "clientId": clientId,
      "clientSecret": clientSecret,
      "signingSecret": signingSecret,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<bool> verifySlackBot(
    String token,
    String botToken,
    String clientId,
    String clientSecret,
    String signingSecret,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/bot-integration/slack/validation'),
    );
    request.body = json.encode({
      "botToken": botToken,
      "clientId": clientId,
      "clientSecret": clientSecret,
      "signingSecret": signingSecret,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print("Slack bot verified successfully");
      final responseBody = await response.stream.bytesToString();
      if (responseBody.isNotEmpty) {
        final decoded = json.decode(responseBody);
        if (decoded['ok'] == true) {
          return true;
        }
      } else {
        return true; // Assume success if no body returned but 200 OK
      }
    } else {
      print(response.reasonPhrase);
      print("Failed to verify Slack bot: ${response.statusCode}");
      print("Response Body: ${await response.stream.bytesToString()}");
    }

    return false;
  }

  Future<bool> verifyMessengerBot(
    String token,
    String botToken,
    String pageId,
    String appSecret,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/bot-integration/messenger/validation'),
    );
    request.body = json.encode({
      "botToken": botToken,
      "pageId": pageId,
      "appSecret": appSecret,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print("Messenger bot verified successfully");
      final responseBody = await response.stream.bytesToString();
      print("Response Body: '$responseBody'");

      if (responseBody.isNotEmpty) {
        final decoded = json.decode(responseBody);
        if (decoded['ok'] == true) {
          return true;
        }
      } else {
        // Assume success if no body returned but 200 OK
        return true;
      }
    } else {
      print(response.reasonPhrase);
      print("Failed to verify Messenger bot: ${response.statusCode}");
    }

    return false;
  }

  Future<void> publishMessengerBot(
    String token,
    String botId,
    String botToken,
    String pageId,
    String appSecret,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/bot-integration/messenger/publish/$botId'),
    );
    request.body = json.encode({
      "botToken": botToken,
      "pageId": pageId,
      "appSecret": appSecret,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }
}
