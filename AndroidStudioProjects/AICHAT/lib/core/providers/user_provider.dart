import 'package:flutter/material.dart';
import 'package:aichat/core/models/User.dart';
import 'package:aichat/core/services/auth.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;
  final AuthService _authService = AuthService();

  void setUser(User? user) {
    _user = user;
    notifyListeners(); // Notifies all widgets that rely on this state
  }

  Future<bool> signUp(String email, String password) async {
    User? newUser = await _authService.signUpWithEmailAndPassword(email, password);
    if (newUser != null) {
      _user = newUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signIn(String email, String password) async {
    User? newUser = await _authService.signInWithEmailAndPassword(email, password);
    if (newUser != null) {
      _user = newUser;
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