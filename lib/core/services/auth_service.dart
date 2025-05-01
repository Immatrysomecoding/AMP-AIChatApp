import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aichat/core/models/UserToken.dart';

class AuthService {
  String baseUrl = 'https://auth-api.dev.jarvis.cx';

  Future<UserToken?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    var headers = {
      'X-Stack-Access-Type': 'client',
      'X-Stack-Project-Id': 'a914f06b-5e46-4966-8693-80e4b9f4f409',
      'X-Stack-Publishable-Client-Key':
          'pck_tqsy29b64a585km2g4wnpc57ypjprzzdch8xzpq0xhayr',
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
          "https://auth.dev.jarvis.cx/handler/email-verification?after_auth_return_to=%2Fauth%2Fsignin%3Fclient_id%3Djarvis_chat%26redirect%3Dhttps%253A%252F%252Fchat.dev.jarvis.cx%252Fauth%252Foauth%252Fsuccess",
    });

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("✅ Sign-up successful");
        print("🔁 Response: $responseBody");
        var jsonResponse = json.decode(responseBody);
        return UserToken.fromJson(jsonResponse);
      } else {
        print("❌ Sign-up failed: ${response.statusCode}");
        print("🔴 Server response: $responseBody");
        return null;
      }
    } catch (e) {
      print("⚠️ Sign-up error: $e");
      return null;
    }
  }

  Future<UserToken?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    var headers = {
      'X-Stack-Access-Type': 'client',
      'X-Stack-Project-Id': 'a914f06b-5e46-4966-8693-80e4b9f4f409',
      'X-Stack-Publishable-Client-Key':
          'pck_tqsy29b64a585km2g4wnpc57ypjprzzdch8xzpq0xhayr',
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
      'X-Stack-Access-Type': 'client',
      'X-Stack-Project-Id': 'a914f06b-5e46-4966-8693-80e4b9f4f409',
      'X-Stack-Publishable-Client-Key':
          'pck_tqsy29b64a585km2g4wnpc57ypjprzzdch8xzpq0xhayr',
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
