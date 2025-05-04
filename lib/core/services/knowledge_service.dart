import 'dart:convert';
import 'package:aichat/core/models/Knowledge.dart';
import 'package:aichat/core/models/KnowledgeUnit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KnowledgeService {
  String baseUrl = dotenv.env['KNOWLEDGE_URL'] ?? '';
  String slackBotToken = dotenv.env['SLACK_BOT_TOKEN'] ?? '';

  Future<List<Knowledge>> fetchKnowledge(String token) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'GET',
      Uri.parse(
        '$baseUrl/kb-core/v1/knowledge?q&order=DESC&order_field=createdAt&offset&limit=20',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final decoded = json.decode(responseBody);
      final dataList = decoded['data'] ?? [];

      return dataList
          .map<Knowledge>((item) => Knowledge.fromJson(item))
          .toList();
    } else {
      print(response.reasonPhrase);
      throw Exception(
        'Failed to fetch knowledge base: ${response.reasonPhrase}',
      );
    }
  }

  Future<void> createKnowledge(
    String token,
    String name,
    String description,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/knowledge'),
    );
    request.body = json.encode({
      "knowledgeName": name,
      "description": description,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print("Create knowledge success");
      final responseBody = await response.stream.bytesToString();
      print("Response: $responseBody");
      return ;
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> updateKnowledge(
    String token,
    String id,
    String name,
    String description,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'PATCH',
      Uri.parse('$baseUrl/kb-core/v1/knowledge/$id'),
    );
    request.body = json.encode({
      "knowledgeName": name,
      "description": description,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> deleteKnowledge(String token, String id) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'DELETE',
      Uri.parse('$baseUrl/kb-core/v1/knowledge/$id'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<List<KnowledgeUnit>> getUnitsOfKnowledge(
    String token,
    String id,
  ) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.Request(
      'GET',
      Uri.parse(
        '$baseUrl/kb-core/v1/knowledge/$id/units?q&order=DESC&order_field=createdAt&offset=&limit=20',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print(responseBody);
      final decoded = json.decode(responseBody);
      final dataList = decoded['data'] ?? [];
      return dataList
          .map<KnowledgeUnit>((item) => KnowledgeUnit.fromJson(item))
          .toList();
    } else {
      print(response.reasonPhrase);
      throw Exception(
        'Failed to fetch knowledge units: ${response.reasonPhrase}',
      );
    }
  }

  Future<void> uploadWebSiteToKnowledge(
    String token,
    String knowledgeId,
    String unitName,
    String url,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/knowledge/$knowledgeId/web'),
    );
    request.body = json.encode({"unitName": unitName, "webUrl": url});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 201) {
      print(await response.stream.bytesToString());
      print("Upload website succes");
    } else {
      print(response.reasonPhrase);
      print("Upload website failed");
    }
  }

  Future<void> uploadLocalFileToKnowledge(
    String token,
    String knowledgeId,
    PlatformFile file,
  ) async {
    var uri = Uri.parse(
      '$baseUrl/kb-core/v1/knowledge/$knowledgeId/local-file',
    );

    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'x-jarvis-guid': '',
        'Authorization': 'Bearer $token',
        // DO NOT manually set Content-Type here; MultipartRequest will handle it
      });

    // Add the file
    // request.files.add(
    //   http.MultipartFile.fromBytes(
    //     'file', // Field name (must match your Java example)
    //     file.bytes!, // PlatformFile gives you bytes
    //     filename: file.name,
    //     contentType: MediaType('application', 'octet-stream'), // generic type
    //   ),
    // );

    try {
      var streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        var responseString = await streamedResponse.stream.bytesToString();
        print("Upload local file success: $responseString");
      } else {
        print(
          "Upload local file failed with status: ${streamedResponse.statusCode}",
        );
        print(await streamedResponse.stream.bytesToString());
      }
    } catch (e) {
      print('Upload failed: $e');
    }
  }

  Future<void> uploadDataFromSlack(
    String token,
    String knowledgeId,
    String unitName,
    String slackWorkSpace,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/knowledge/$knowledgeId/slack'),
    );
    request.body = json.encode({
      "unitName": unitName,
      "slackWorkspace": slackWorkSpace,
      "slackBotToken": slackBotToken,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> uploadDataFromGGDrive(String token, String knowledgeId) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/kb-core/v1/knowledge/$knowledgeId/google-drive',
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
}
