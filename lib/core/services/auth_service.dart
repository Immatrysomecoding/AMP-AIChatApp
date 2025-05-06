import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aichat/core/models/UserToken.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  String baseUrl = dotenv.env['AUTH_URL'] ?? '';

  Future<UserToken?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    var headers = {
      'X-Stack-Access-Type': dotenv.env['STACK_ACCESS_TYPE'] ?? 'client',
      'X-Stack-Project-Id': dotenv.env['STACK_PROJECT_ID'] ?? '',
      'X-Stack-Publishable-Client-Key': dotenv.env['STACK_CLIENT_KEY'] ?? '',
      'Content-Type': 'application/json',
    };

    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/v1/auth/password/sign-up'),
    );

    request.body = json.encode({
      "email": email,
      "password": password,
      "verification_callback_url":
          dotenv.env['VERIFICATION_CALLBACK_URL'] ?? '',
    });

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        return UserToken.fromJson(jsonResponse);
      } else {
        var error = json.decode(responseBody);
        throw error['error'] ?? 'Sign-up failed';
      }
    } catch (e) {
      throw 'Sign-up error: $e';
    }
  }

  Future<UserToken?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    var headers = {
      'X-Stack-Access-Type': dotenv.env['STACK_ACCESS_TYPE'] ?? '',
      'X-Stack-Project-Id': dotenv.env['STACK_PROJECT_ID'] ?? '',
      'X-Stack-Publishable-Client-Key': dotenv.env['STACK_CLIENT_KEY'] ?? '',
      'Content-Type': 'application/json',
    };

    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/v1/auth/password/sign-in'),
    );

    request.body = json.encode({"email": email, "password": password});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("✅ Login successful");
        print("🔁 Response: $responseBody");
        var jsonResponse = json.decode(responseBody);
        return UserToken.fromJson(jsonResponse);
      } else {
        print("❌ Login failed: ${response.statusCode}");
        print("🔴 Server response: $responseBody");
        return null;
      }
    } catch (e) {
      print("⚠️ Login error: $e");
      return null;
    }
  }

  Future<void> logOut(String token, String refreshToken) async {
    var headers = {
      'Authorization': 'Bearer $token',
      'X-Stack-Access-Type': dotenv.env['STACK_ACCESS_TYPE'] ?? '',
      'X-Stack-Project-Id': dotenv.env['STACK_PROJECT_ID'] ?? '',
      'X-Stack-Publishable-Client-Key': dotenv.env['STACK_CLIENT_KEY'] ?? '',
      'X-Stack-Refresh-Token': refreshToken,
      'Content-Type': 'application/json',
    };

    var request = http.Request(
      'DELETE',
      Uri.parse('$baseUrl/api/v1/auth/sessions/current'),
    );
    request.headers.addAll(headers);
    request.body = json.encode({});

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      print("✅ Logout successful");
      print(responseBody);
    } else {
      print("❌ Logout failed (${response.statusCode})");
      print(responseBody);
    }
  }
}

void main() async {
  final auth = AuthService();

  final email = 'test1234@example.com';
  final password = 'MySecurePassword123';

  print("🔵 Signing up...");
  UserToken? signUpResult = await auth.signUpWithEmailAndPassword(
    email,
    password,
  );

  if (signUpResult != null) {
    print("✅ [Sign-up] Access Token: ${signUpResult.accessToken}");
  } else {
    print("❌ Sign-up failed (may already exist)");
  }

  print("🔵 Signing in...");
  UserToken? signInResult = await auth.signInWithEmailAndPassword(
    email,
    password,
  );

  if (signInResult != null) {
    print("✅ [Login] Access Token: ${signInResult.accessToken}");
  } else {
    print("❌ Login failed (wrong password or email)");
  }
}
