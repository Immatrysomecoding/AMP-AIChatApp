import 'package:flutter/material.dart';
import 'package:aichat/core/models/Prompt.dart';
import 'package:aichat/core/services/prompt_service.dart';

class PromptProvider with ChangeNotifier {
  List<Prompt> _prompts = [];
  List<Prompt> _publicPrompts = [];
  final PromptService _promptService = PromptService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Prompt> get prompts => _prompts;
  List<Prompt> get publicPrompts => _publicPrompts;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchPrivatePrompts(String token) async {
    _isLoading = true;
    notifyListeners();
    _prompts = await _promptService.getPrivatePrompts(token);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPublicPrompts(String token) async {
    _isLoading = true;
    notifyListeners();
    _publicPrompts = await _promptService.getPublicPrompts(token);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPrompt(
    String title,
    String content,
    String description,
    String token,
  ) async {
    await _promptService.addPrompt(title, content, description, token);

    // Refetch the prompts after adding a new prompt
    await fetchPrivatePrompts(token);
    await fetchPublicPrompts(token);

    notifyListeners(); // Notify listeners after the lists are refreshed
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
