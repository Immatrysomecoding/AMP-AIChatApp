import 'package:flutter/material.dart';
import 'package:aichat/core/models/Prompt.dart';
import 'package:aichat/core/services/prompt_service.dart';

class PromptProvider with ChangeNotifier {
  List<Prompt> _prompts = [];
  final PromptService _promptService = PromptService();

  List<Prompt> get prompts => _prompts;

  Future<void> fetchPrompts(String token) async {
    _prompts = await _promptService.getPrompts(token);
    notifyListeners();
  }

  Future<void> fetchPublicPrompts(String token) async {
    _prompts = await _promptService.getPublicPrompts(token);
    notifyListeners();
  }

  Future<void> addPrompt(
    String title,
    String content,
    String description,
    String token,
  ) async {
    await _promptService.addPrompt(title, content, description, token);

    notifyListeners();
  }

  Future<void> deletePrompt(String id, String token) async {
    print("id: $id");
    print("token: $token");

    await _promptService.deletePrompt(id, token);

    notifyListeners();
  }

  Future<void> addPromptToFavorite(String id, String token) async {
    await _promptService.addPromptToFavorite(id, token);

    notifyListeners();
  }

  Future<void> removePromptFromFavorite(String id, String token) async {
    await _promptService.removePromptFromFavorite(id, token);

    notifyListeners();
  }

  Future<void> updatePrompt(
    String? id,
    String title,
    String content,
    String description,
    String token,
  ) async {
    await _promptService.updatePrompt(id!, title, content, description, token);

    notifyListeners();
  }
}
