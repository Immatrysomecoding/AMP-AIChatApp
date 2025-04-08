import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aichat/core/models/Prompt.dart';

class PromptService {
  Future<List<Prompt>> getPrompts(String token) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var response = await http.get(
      Uri.parse(
        'https://api.dev.jarvis.cx/api/v1/prompts?query&offset=&limit=20&isFavorite=false&isPublic=false',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);

      List<dynamic> items = responseBody['items'];
      // Mapping items to Prompt model
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
    var request = http.Request(
      'POST',
      Uri.parse('https://api.dev.jarvis.cx/api/v1/prompts'),
    );
    request.body = json.encode({
      "title": title,
      "content": content,
      "description": description,
      "isPublic": false,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 201) {
      print(await response.stream.bytesToString());
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
      Uri.parse('https://api.dev.jarvis.cx/api/v1/prompts/$id'),
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
      Uri.parse('https://api.dev.jarvis.cx/api/v1/prompts/$id/favorite'),
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
      Uri.parse('https://api.dev.jarvis.cx/api/v1/prompts/$id/favorite'),
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
}
