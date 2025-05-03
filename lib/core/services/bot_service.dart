import 'dart:convert';
import 'package:aichat/core/models/Knowledge.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:aichat/core/models/Bot.dart';

class BotService {
  String baseUrl = dotenv.env['KNOWLEDGE_URL'] ?? "";

  Future<List<Bot>> fetchBots(String token) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};

    var request = http.Request(
      'GET',
      Uri.parse(
        '$baseUrl/kb-core/v1/ai-assistant?q&order=DESC&order_field=createdAt&offset&limit=20&is_published',
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

  Future<void> createThreadForBot(
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
      Uri.parse('$baseUrl/kb-core/v1/ai-assistant/thread'),
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

  Future<void> askBot(String token, String botId, String msg, String openAiThreadId, String additionalInstruction) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse(
        '$baseUrl/kb-core/v1/ai-assistant/$botId/ask',
      ),
    );
    request.body = json.encode({
      "message": msg,
      "openAiThreadId": openAiThreadId,
      "additionalInstruction": additionalInstruction,
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
