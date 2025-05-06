import 'package:flutter/material.dart';
import 'package:aichat/core/models/UserToken.dart' as model;
import 'package:aichat/core/services/auth_service.dart';

class UserTokenProvider with ChangeNotifier {
  model.UserToken? _user;
  final AuthService _authService = AuthService();
  bool _isInitializing = false;

  model.UserToken? get user => _user;
  bool get isInitializing => _isInitializing;

  void setUser(model.UserToken? user) {
    _user = user;
    notifyListeners();
  }

  // For adding an initializing state
  void setInitializing(bool initializing) {
    _isInitializing = initializing;
    notifyListeners();
  }

  Future<bool> signUp(String email, String password) async {
    setInitializing(true);
    try {
      model.UserToken? newUser = await _authService.signUpWithEmailAndPassword(
        email,
        password,
      );

      if (newUser != null) {
        setUser(newUser);
        return true;
      }

      return false;
    } catch (e) {
      print("Error during signup: $e");
      return false;
    } finally {
      setInitializing(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    setInitializing(true);

    try {
      model.UserToken? newUser = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (newUser != null) {
        setUser(newUser);
        setInitializing(false);
        return true;
      }

      setInitializing(false);
      return false;
    } catch (e) {
      print("Error during sign in: $e");
      setInitializing(false);
      return false;
    }
  }

  Future<void> logout() async {
    if (_user == null) return;

    setInitializing(true);

    try {
      await _authService.logOut(_user!.accessToken, _user!.refreshToken);
    } catch (e) {
      print("Logout failed: $e");
    }

    _user = null;
    setInitializing(false);
    notifyListeners();
  }

  // Check if user has an active token (can be used at app startup)
  bool hasActiveSession() {
    return _user != null && _user!.accessToken.isNotEmpty;
  }
}
