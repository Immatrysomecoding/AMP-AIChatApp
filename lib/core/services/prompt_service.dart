import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aichat/core/models/Prompt.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PromptService {
  String baseUrl = dotenv.env['CHAT_URL'] ?? '';

  Future<List<Prompt>> getPublicPrompts(String token) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var response = await http.get(
      Uri.parse(
        '$baseUrl/api/v1/prompts?query&offset=&limit=20&isFavorite=false&isPublic=true',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);

      List<dynamic> items = responseBody['items'];
      print("items: $items");

      return items.map((data) => Prompt.fromJson(data)).toList();
    } else {
      throw Exception("Failed to fetch prompts: ${response.reasonPhrase}");
    }
  }

  Future<List<Prompt>> getPrivatePrompts(String token) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var response = await http.get(
      Uri.parse(
        '$baseUrl/api/v1/prompts?query&offset=&limit=20&isFavorite=false&isPublic=false',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);

      List<dynamic> items = responseBody['items'];

      return items.map((data) => Prompt.fromJson(data)).toList();
    } else {
      throw Exception("Failed to fetch prompts: ${response.reasonPhrase}");
    }
  }

  Future<List<Prompt>> getPublicFavoritePrompts(String token) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var response = await http.get(
      Uri.parse(
        '$baseUrl/api/v1/prompts?query&offset=&limit=20&isFavorite=true&isPublic=true',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);

      List<dynamic> items = responseBody['items'];
      print("items: $items");

      return items.map((data) => Prompt.fromJson(data)).toList();
    } else {
      throw Exception("Failed to fetch prompts: ${response.reasonPhrase}");
    }
  }

  Future<List<Prompt>> getPrivateFavoritePrompts(String token) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var response = await http.get(
      Uri.parse(
        '$baseUrl/api/v1/prompts?query&offset=&limit=20&isFavorite=true&isPublic=false',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);

      List<dynamic> items = responseBody['items'];
      print("items: $items");

      return items.map((data) => Prompt.fromJson(data)).toList();
    } else {
      throw Exception("Failed to fetch prompts: ${response.reasonPhrase}");
    }
  }

  Future<Prompt?> addPrompt(
    String title,
    String content,
    String description,
    String token,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request('POST', Uri.parse('$baseUrl/api/v1/prompts'));
    request.body = json.encode({
      "title": title,
      "content": content,
      "description": description,
      "isPublic": false,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      print(responseBody);
      return Prompt.fromJson(json.decode(responseBody));
    } else {
      print("Failed to add prompt: ${response.reasonPhrase}");
    }

    return null;
  }

  Future<void> deletePrompt(String id, String token) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'DELETE',
      Uri.parse('$baseUrl/api/v1/prompts/$id'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
      print("Error");
    }
  }

  Future<void> addPromptToFavorite(String id, String token) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/v1/prompts/$id/favorite'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 201) {
      print(await response.stream.bytesToString());
      print("Added to favorites");
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> removePromptFromFavorite(String id, String token) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'DELETE',
      Uri.parse('$baseUrl/api/v1/prompts/$id/favorite'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
      print("Removed from favorites");
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> updatePrompt(
    String id,
    String title,
    String content,
    String description,
    String token,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'PATCH',
      Uri.parse('$baseUrl/api/v1/prompts/$id'),
    );
    request.body = json.encode({
      "title": title,
      "description": description,
      "content": content,
      "isPublic": false,
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
