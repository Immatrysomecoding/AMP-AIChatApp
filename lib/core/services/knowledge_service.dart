import 'dart:convert';
import 'package:aichat/core/models/Knowledge.dart';
import 'package:aichat/core/models/KnowledgeUnit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';

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

  Future<void> uploadLocalFileToKnowledge({
    required String token,
    required String knowledgeId,
    required PlatformFile file,
  }) async {
    // Step 1: Upload file to get fileId
    final uploadUri = Uri.parse('$baseUrl/kb-core/v1/knowledge/files');
    final uploadRequest = http.MultipartRequest('POST', uploadUri);
    uploadRequest.headers.addAll({'Authorization': 'Bearer $token'});

    print("Here");

    if (file.bytes != null) {
      uploadRequest.files.add(
        http.MultipartFile.fromBytes(
          'files',
          file.bytes!,
          filename: file.name,
          contentType: MediaType('application', 'octet-stream'),
        ),
      );
    } else if (file.path != null) {
      uploadRequest.files.add(
        await http.MultipartFile.fromPath(
          'files',
          file.path!,
          filename: file.name,
          contentType: MediaType('application', 'octet-stream'),
        ),
      );
    } else {
      print('❌ Invalid file: no bytes or path.');
      return;
    }
    print("File upload success");
    print("File name: ${file.name}");
    print("File path: ${file.path}");
    print("File bytes: ${file.bytes}");
    print("File size: ${file.size}");
    print("File extension: ${file.extension}");
    final uploadResponse = await uploadRequest.send();
    final uploadBody = await uploadResponse.stream.bytesToString();

    print("Upload response: $uploadBody");
    print("Upload status code: ${uploadResponse.statusCode}");

    final decoded = json.decode(uploadBody);
    print('🟡 Decoded response: $decoded');

    final fileList = decoded['files'];
    if (fileList is! List || fileList.isEmpty || fileList[0]['id'] == null) {
      print("❌ Invalid response structure or missing file ID.");
      return;
    }

    final fileId = fileList[0]['id'];
    print("✅ File uploaded. ID: $fileId");

    // Step 2: Register uploaded file as knowledge datasource
    final registerUri = Uri.parse(
      '$baseUrl/kb-core/v1/knowledge/$knowledgeId/datasources',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'x-jarvis-guid': '', // optional, include if needed
    };

    final body = json.encode({
      "datasources": [
        {
          "type": "local_file",
          "name": file.name,
          "credentials": {"file": fileId},
        },
      ],
    });

    final request =
        http.Request('POST', registerUri)
          ..headers.addAll(headers)
          ..body = body;

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      print("✅ File linked to knowledge base.");
      print(responseBody);
    } else {
      print("❌ Linking failed");
      print("Status code: ${response.statusCode}");
      print("Error body: $responseBody");
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
    request.body = json.encode({
      "status": !unitStatus,
    });
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
}
