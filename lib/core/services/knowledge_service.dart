import 'dart:convert';
import 'package:aichat/core/models/Knowledge.dart';
import 'package:aichat/core/models/KnowledgeUnit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';

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
      return;
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
        '$baseUrl/kb-core/v1/knowledge/$id/datasources?q&order=DESC&order_field=createdAt&offset=&limit=20',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    print("Status code:$response.statusCode");

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print("units OF KNOWLEDGE");
      final decoded = json.decode(responseBody);
      final dataList = decoded['data'] ?? [];
      print("Data list: $dataList");
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
      final errorBody = await response.stream.bytesToString();
      print("Upload website failed");
      print("Status code: ${response.statusCode}");
      print("Reason: ${response.reasonPhrase}");
      print("Error body: $errorBody");
    }
  }

  Future<String> uploadLocalFile(String token, PlatformFile file) async {
    var headers = {'Authorization': 'Bearer $token', 'x-jarvis-guid': ''};

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/knowledge/files'),
    );

    request.headers.addAll(headers);

    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('files', file.bytes!, filename: file.name),
      );
    } else {
      throw Exception(
        "file.bytes is null. This won't work on web unless you pick bytes.",
      );
    }

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      print("response body: $responseBody");
      print("Status code: ${response.statusCode}");
      final decoded = json.decode(responseBody);
      print("Decoded: $decoded");
      return decoded['id'];
    } else {
      print("Upload failed");
      print("Status code: ${response.statusCode}");
      final errorBody = await response.stream.bytesToString();
      print("Error body: $errorBody");
      return "";
    }
  }

  // String _getMimeType(String ext) {
  //   switch (ext.toLowerCase()) {
  //     case 'pdf':
  //       return 'application';
  //     case 'doc':
  //     case 'docx':
  //       return 'application';
  //     case 'txt':
  //       return 'text';
  //     default:
  //       return 'application';
  //   }
  // }

  // String _getSubMimeType(String ext) {
  //   switch (ext.toLowerCase()) {
  //     case 'pdf':
  //       return 'pdf';
  //     case 'doc':
  //       return 'msword';
  //     case 'docx':
  //       return 'vnd.openxmlformats-officedocument.wordprocessingml.document';
  //     case 'txt':
  //       return 'plain';
  //     default:
  //       return 'octet-stream';
  //   }
  // }

  Future<void> uploadLocalFilesToKnowledge(
    String token,
    String knowledgeId,
    List<PlatformFile> files,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer ',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/knowledge/$knowledgeId/datasources'),
    );
    request.body = json.encode({
      "datasources": [
        {
          "name": "string",
          "type": "local_file",
          "credentials": {
            "email": "string",
            "file": "string",
            "info": {},
            "password": "string",
            "token": "string",
            "url": "string",
            "username": "string",
            "type": "string",
          },
        },
      ],
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> uploadDataFromSlack(
    String token,
    String knowledgeId,
    String unitName,
    String slackBotToken,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/knowledge/$knowledgeId/datasources'),
    );
    request.body = json.encode({
      "datasources": [
        {
          "type": "slack",
          "name": unitName,
          "credentials": {"token": slackBotToken},
        },
      ],
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 201) {
      print(await response.stream.bytesToString());
      print("Upload slack success");
    } else {
      final errorBody = await response.stream.bytesToString();
      print("Upload slack failed");
      print("Status code: ${response.statusCode}");
      print("Error body: $errorBody");
    }
  }

  Future<void> uploadDataFromGGDrive(String token, String knowledgeId) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/kb-core/v1/knowledge/$knowledgeId/google-drive'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> toggleKnowledgeUnitStatus(
    String token,
    String knowledgeId,
    String unitId,
    bool unitStatus,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    var request = http.Request(
      'PATCH',
      Uri.parse(
        '$baseUrl/kb-core/v1/knowledge/$knowledgeId/datasources/$unitId',
      ),
    );
    // might get rid of this later
    request.body = json.encode({"status": !unitStatus});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
      print("Toggle knowledge unit status success");
    } else {
      print(response.reasonPhrase);
      print(response.statusCode);
      print("Toggle knowledge unit status failed");
    }
  }

  Future<void> deleteKnowledgeUnit(
    String token,
    String knowledgeId,
    String unitId,
  ) async {
    var headers = {
      'x-jarvis-guid': '',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var request = http.Request(
      'DELETE',
      Uri.parse(
        '$baseUrl/kb-core/v1/knowledge/$knowledgeId/datasources/$unitId',
      ),
    );

    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 204) {
      print(await response.stream.bytesToString());
      print("Delete knowledge unit success");
    } else {
      print(response.reasonPhrase);
      print(response.statusCode);
      print("Delete knowledge unit status failed");
    }
  }
}
