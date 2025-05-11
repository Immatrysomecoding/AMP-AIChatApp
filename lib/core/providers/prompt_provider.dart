import 'package:flutter/material.dart';
import 'package:aichat/core/models/Prompt.dart';
import 'package:aichat/core/services/prompt_service.dart';

class PromptProvider with ChangeNotifier {
  List<Prompt> _prompts = [];
  List<Prompt> _publicPrompts = [];
  final PromptService _promptService = PromptService();

  List<Prompt> get prompts => _prompts;
  List<Prompt> get publicPrompts => _publicPrompts;

  Future<void> fetchPrivatePrompts(String token) async {
    _prompts = await _promptService.getPrivatePrompts(token);
    notifyListeners();
  }

  Future<void> fetchPublicPrompts(String token) async {
    _publicPrompts = await _promptService.getPublicPrompts(token);
    notifyListeners();
  }

  Future<void> fetchPublicFavoritePrompts(String token) async {
    _publicPrompts = await _promptService.getPublicFavoritePrompts(token);
    notifyListeners();
  }

  Future<void> fetchPrivateFavoritePrompts(String token) async {
    _prompts = await _promptService.getPrivateFavoritePrompts(token);
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
