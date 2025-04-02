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

  Future<void> addPrompt(String title, String content,String description , String token) async {
    await _promptService.addPrompt(title, content, description, token);
    // Optionally, you can fetch the prompts again to refresh the list
    // _prompts = await _promptService.getPrompts(token);
    notifyListeners();
  }
}