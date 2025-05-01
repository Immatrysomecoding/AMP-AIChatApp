import 'package:flutter/material.dart';
import 'package:aichat/core/models/AIModel.dart';
import 'package:aichat/core/services/chat_service.dart';

class AIModelProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<AIModel> _availableModels = [];
  AIModel? _selectedModel;
  bool _isLoading = false;

  // Getters
  List<AIModel> get availableModels => _availableModels;
  AIModel? get selectedModel => _selectedModel;
  bool get isLoading => _isLoading;

  // Fetch available AI models
  Future<void> fetchAvailableModels(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      _availableModels = await _chatService.getAvailableModels(token);

      // Set a default selected model if none is selected yet
      if (_selectedModel == null && _availableModels.isNotEmpty) {
        _selectedModel = _availableModels.firstWhere(
          (model) => model.isDefault,
          orElse: () => _availableModels.first,
        );
      }
    } catch (e) {
      print('Error fetching available models: $e');
      // Don't clear _availableModels on error to maintain UI state
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set selected AI model with smoother state transition
  void setSelectedModel(AIModel model) {
    // First check if the model already exists in our list
    final existingModel = _availableModels.firstWhere(
      (m) => m.id == model.id,
      orElse: () => model,
    );

    _selectedModel = existingModel;
    notifyListeners();
  }
}
