import 'package:aichat/core/models/Knowledge.dart';
import 'package:aichat/core/models/KnowledgeUnit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:aichat/core/services/knowledge_service.dart';

class KnowledgeProvider with ChangeNotifier {
  List<Knowledge> _knowlegdes = [];
  List<Knowledge> get knowledges => _knowlegdes;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final KnowledgeService _knowledgeService = KnowledgeService();

  Future<void> fetchKnowledges(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      _knowlegdes = await _knowledgeService.fetchKnowledge(token);
    } catch (e) {
      print('Error fetching knowledges: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createKnowledge(
    String token,
    String name,
    String description,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _knowledgeService.createKnowledge(token, name, description);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteKnowledge(String token, String knowledgeId) async {
    _isLoading = true;
    notifyListeners();
    await _knowledgeService.deleteKnowledge(token, knowledgeId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateKnowledge(
    String token,
    String knowledgeId,
    String name,
    String description,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _knowledgeService.updateKnowledge(
      token,
      knowledgeId,
      name,
      description,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<List<KnowledgeUnit>> getUnitsOfKnowledge(
    String token,
    String knowledgeId,
  ) async {
    _isLoading = true;
    notifyListeners();
    final List<KnowledgeUnit> units = await _knowledgeService
        .getUnitsOfKnowledge(token, knowledgeId);
    _isLoading = false;
    notifyListeners();
    return units;
  }

  Future<void> uploadWebSiteToKnowledge(
    String token,
    String knowledgeId,
    String unitName,
    String url,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _knowledgeService.uploadWebSiteToKnowledge(
      token,
      knowledgeId,
      unitName,
      url,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<String> uploadLocalFile(String token, PlatformFile file) async {
    _isLoading = true;
    notifyListeners();
    String fileId = await _knowledgeService.uploadLocalFile(token, file);
    _isLoading = false;
    notifyListeners();

    return fileId;
  }

  Future<void> uploadLocalFilesToKnowledge(
    String token,
    String knowledgeId,
    List<PlatformFile> files,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _knowledgeService.uploadLocalFilesToKnowledge(
      token,
      knowledgeId,
      files
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadSlackToKnowledge(
    String token,
    String knowledgeId,
    String unitName,
    String slackToken,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _knowledgeService.uploadDataFromSlack(
      token,
      knowledgeId,
      unitName,
      slackToken,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadConfluenceToKnowledge(String token, String knowledgeId, String unitName, String wikiUrl, String username, String apiToken) async {
    _isLoading = true;
    notifyListeners();
    await _knowledgeService.uploadConfluenceToKnowledge(token, knowledgeId, unitName, wikiUrl, username, apiToken);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleKnowledgeUnitStatus(
    String token,
    String knowledgeId,
    String unitId,
    bool unitStatus,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _knowledgeService.toggleKnowledgeUnitStatus(
      token,
      knowledgeId,
      unitId,
      unitStatus,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteKnowledgeUnit(
    String token,
    String knowledgeId,
    String unitId,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _knowledgeService.deleteKnowledgeUnit(token, knowledgeId, unitId);
    _isLoading = false;
    notifyListeners();
  }
}
