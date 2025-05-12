import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SubscriptionService {
  String baseUrl = dotenv.env['CHAT_URL'] ?? 'https://api.dev.jarvis.cx';

  // Subscribe to Pro plan
  Future<bool> subscribe(String token) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};

    print(
      'Attempting to subscribe with token: ${token.substring(0, 10)}...',
    ); // Debug log

    var request = http.Request(
      'GET',
      Uri.parse('$baseUrl/api/v1/subscriptions/subscribe'),
    );
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Subscribe response status: ${response.statusCode}'); // Debug log
      print('Subscribe response body: $responseBody'); // Debug log

      if (response.statusCode == 200) {
        print("Successfully subscribed to Pro plan");
        return true;
      } else {
        print("Failed to subscribe: ${response.reasonPhrase}");
        return false;
      }
    } catch (e) {
      print("Error subscribing: $e");
      return false;
    }
  }

  // Get subscription details
  Future<Map<String, dynamic>?> getSubscriptionDetails(String token) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};

    var request = http.Request(
      'GET',
      Uri.parse('$baseUrl/api/v1/subscriptions/me'),
    );
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Subscription details: $responseBody'); // Debug log
        return json.decode(responseBody);
      } else {
        print("Failed to get subscription details: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Error getting subscription details: $e");
      return null;
    }
  }

  // Get token usage
  Future<Map<String, dynamic>?> getTokenUsage(String token) async {
    var headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};

    var request = http.Request(
      'GET',
      Uri.parse('$baseUrl/api/v1/tokens/usage'),
    );
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Token usage: $responseBody'); // Debug log
        return json.decode(responseBody);
      } else {
        print("Failed to get token usage: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Error getting token usage: $e");
      return null;
    }
  }
}
