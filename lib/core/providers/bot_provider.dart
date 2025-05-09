import 'package:aichat/core/models/BotConfiguration.dart';
import 'package:aichat/core/models/Knowledge.dart';
import 'package:flutter/material.dart';
import 'package:aichat/core/models/Bot.dart';
import 'package:aichat/core/services/bot_service.dart';

class BotProvider with ChangeNotifier {
  List<Bot> _bots = [];
  List<Bot> get bots => _bots;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<BotConfiguration> _botConfigurations = [];
  List<BotConfiguration> get botConfigurations => _botConfigurations;

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
    await _botService.updateBot(
      token,
      botId,
      botName,
      instruction,
      description,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<List<Knowledge>> getImportedKnowledge(
    String token,
    String botId,
  ) async {
    _isLoading = true;
    notifyListeners();
    List<Knowledge> knowledge = await _botService.getImportedKnowledge(
      token,
      botId,
    );
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

  Future<void> importKnowledgeToBot(
    String token,
    String botId,
    String knowledgeId,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _botService.importKnowledgeToBot(token, botId, knowledgeId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> getBotConfiguration(String token, String botId) async {
    _isLoading = true;
    notifyListeners();

    _botConfigurations = await _botService.getBotConfiguration(token, botId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> disconnectBotConfiguration(
    String token,
    String botId,
    String type,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _botService.disconnectBotConfiguration(token, botId, type);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> verifyTelegramBot(String token, String botToken) async {
    _isLoading = true;
    notifyListeners();
    bool result = await _botService.verifyTelegramBot(token, botToken);
    _isLoading = false;
    notifyListeners();
    if (result) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> verifySlackBot(
    String token,
    String botToken,
    String clientId,
    String clientSecret,
    String signingSecret,
  ) async {
    _isLoading = true;
    notifyListeners();
    bool result = await _botService.verifySlackBot(
      token,
      botToken,
      clientId,
      clientSecret,
      signingSecret,
    );
    _isLoading = false;
    notifyListeners();
    if (result) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> verifyMessengerBot(
    String token,
    String botToken,
    String pageId,
    String appSecret,
  ) async {
    _isLoading = true;
    notifyListeners();
    bool result = await _botService.verifyMessengerBot(
      token,
      botToken,
      pageId,
      appSecret,
    );
    _isLoading = false;
    notifyListeners();
    if (result) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> publishTelegramBot(
    String token,
    String botId,
    String botToken,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _botService.publishTelegramBot(token, botId, botToken);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> publishSlackBot(
    String token,
    String botId,
    String botToken,
    String clientId,
    String clientSecret,
    String signingSecret,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _botService.publishSlackBot(
      token,
      botId,
      botToken,
      clientId,
      clientSecret,
      signingSecret,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> publishMessengerBot(
    String token,
    String botId,
    String botToken,
    String pageId,
    String appSecret,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _botService.publishMessengerBot(
      token,
      botId,
      botToken,
      pageId,
      appSecret,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> createThreadForBot(
    String token,
    String botId,
    String firstMsg,
  ) async {
    _isLoading = true;
    notifyListeners();

    Map<String, dynamic>? result;
    try {
      result = await _botService.createThreadForBot(token, botId, firstMsg);
    } catch (e) {
      print("Error creating thread in provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>?> askBot(
    String token,
    String botId,
    String msg,
    String openAiThreadId,
    String additionalInstruction, {
    Function(String)? onChunkReceived,
  }) async {
    _isLoading = true;
    notifyListeners();

    Map<String, dynamic>? result;
    try {
      result = await _botService.askBot(
        token,
        botId,
        msg,
        openAiThreadId,
        additionalInstruction,
        onChunkReceived: onChunkReceived,
      );
    } catch (e) {
      print("Error asking bot in provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return result;
  }
}
