import 'package:flutter/material.dart';
import 'package:aichat/core/models/UserToken.dart';
import 'package:aichat/core/services/auth_service.dart';

class UserTokenProvider with ChangeNotifier {
  UserToken? _user;

  UserToken? get user => _user;
  final AuthService _authService = AuthService();

  void setUser(UserToken? user) {
    _user = user;
    notifyListeners(); // Notifies all widgets that rely on this state
  }

  Future<bool> signUp(String email, String password) async {
    UserToken? newUser = await _authService.signUpWithEmailAndPassword(email, password);
    if (newUser != null) {
      setUser(newUser);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signIn(String email, String password) async {
    UserToken? newUser = await _authService.signInWithEmailAndPassword(email, password);
    if (newUser != null) {
      setUser(newUser);
      print("User signed in with token: ${newUser.accessToken}");
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    if (_user == null) return;

    try {
      await _authService.logOut(_user!.accessToken, _user!.refreshToken);
    } catch (e) {
      print("Logout failed: $e");
    }

    _user = null;
    notifyListeners();
  }
}