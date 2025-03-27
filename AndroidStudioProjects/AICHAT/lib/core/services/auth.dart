import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    var headers = {
      'X-Stack-Access-Type': 'client',
      'X-Stack-Project-Id': 'a914f06b-5e46-4966-8693-80e4b9f4f409',
      'X-Stack-Publishable-Client-Key':
          'pck_tqsy29b64a585km2g4wnpc57ypjprzzdch8xzpq0xhayr',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('https://auth-api.dev.jarvis.cx/api/v1/auth/password/sign-up'),
    );
    request.body = json.encode({
      "email": email,
      "password": password,
      "verification_callback_url":
          "https://auth.dev.jarvis.cx/handler/email-verification?after_auth_return_to=%2Fauth%2Fsignin%3Fclient_id%3Djarvis_chat%26redirect%3Dhttps%253A%252F%252Fchat.dev.jarvis.cx%252Fauth%252Foauth%252Fsuccess",
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    var headers = {
      'X-Stack-Access-Type': 'client',
      'X-Stack-Project-Id': 'a914f06b-5e46-4966-8693-80e4b9f4f409',
      'X-Stack-Publishable-Client-Key':
          'pck_tqsy29b64a585km2g4wnpc57ypjprzzdch8xzpq0xhayr',
      'Content-Type': 'application/json',
    };
    var request = http.Request(
      'POST',
      Uri.parse('https://auth-api.dev.jarvis.cx/api/v1/auth/password/sign-in'),
    );
    request.body = json.encode({
      "email": email,
      "password": password,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }
}