import 'package:aichat/core/models/Knowledge.dart';
import 'package:flutter/material.dart';
import 'package:aichat/core/models/Bot.dart';
import 'package:aichat/core/services/bot_service.dart';

class BotProvider with ChangeNotifier{
  List<Bot> _bots = [];
  List<Bot> get bots => _bots;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final BotService _botService = BotService();

  Future<void> fetchBots(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch your bots (mock or real API)
      _bots = await _botService.fetchBots(token);
    } catch (e) {
      print('Error fetching bots: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBot(
    String token,
    String botName,
    String instruction,
    String description,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _botService.createBot(token, botName, instruction, description);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteBot(String token, String botId) async {
    _isLoading = true;
    notifyListeners();
    await _botService.deleteBot(token, botId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavoriteBot(String token, String botId) async {
    _isLoading = true;
    notifyListeners();
    await _botService.toggleFavoriteBot(token, botId);
    _isLoading = false;
    notifyListeners();

  }

  Future<void> updateBot(
    String token,
    String botId,
    String botName,
    String instruction,
    String description,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _botService.updateBot(token, botId, botName, instruction, description);
    _isLoading = false;
    notifyListeners();
  }

  Future<List<Knowledge>> getImportedKnowledge(String token, String botId) async {
    _isLoading = true;
    notifyListeners();
    List<Knowledge> knowledge = await _botService.getImportedKnowledge(token, botId);
    _isLoading = false;
    notifyListeners();
    return knowledge;
  }

  Future<void> deleteKnowledgeFromBot(
    String token,
    String botId,
    String knowledgeId,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _botService.deleteKnowledgeFromBot(token, botId, knowledgeId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> importKnowledgeToBot(String token, String botId, String knowledgeId) async {
    _isLoading = true;
    notifyListeners();
    await _botService.importKnowledgeToBot(token, botId, knowledgeId);
    _isLoading = false;
    notifyListeners();
  }
}