import 'package:flutter/material.dart';

class SubscriptionStateManager extends ChangeNotifier {
  static final SubscriptionStateManager _instance =
      SubscriptionStateManager._internal();

  factory SubscriptionStateManager() {
    return _instance;
  }

  SubscriptionStateManager._internal();

  bool _isPro = false;
  int _availableTokens = 50;

  bool get isPro => _isPro;
  int get availableTokens => _isPro ? 999999 : _availableTokens;
  bool get isUnlimited => _isPro;

  void upgradeToPro() {
    _isPro = true;
    notifyListeners();
  }

  void setTokens(int tokens) {
    if (!_isPro) {
      _availableTokens = tokens;
      notifyListeners();
    }
  }

  void useToken() {
    if (!_isPro && _availableTokens > 0) {
      _availableTokens--;
      notifyListeners();
    }
  }

  void reset() {
    _isPro = false;
    _availableTokens = 50;
    notifyListeners();
  }
}
