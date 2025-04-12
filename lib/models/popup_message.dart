// Create this file at lib/models/popup_message.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PopupMessage {
  final bool display;
  final String message;

  PopupMessage({required this.display, required this.message});

  factory PopupMessage.fromJson(Map<String, dynamic> json) {
    // Add debug prints to see what's in the json
    debugPrint('PopupMessage.fromJson input: $json');

    bool displayValue = false;

    // Handle different types for display value
    if (json['display'] is bool) {
      displayValue = json['display'];
    } else if (json['display'] is String) {
      displayValue =
          json['display'].toLowerCase() == 'true' || json['display'] == '1';
    } else if (json['display'] is int) {
      displayValue = json['display'] == 1;
    }

    debugPrint('PopupMessage parsed display value: $displayValue');

    return PopupMessage(
      display: displayValue,
      message: json['message']?.toString() ?? '',
    );
  }

  static Future<PopupMessage?> fetchFromApi() async {
    try {
      final url = Uri.parse(
        'https://algodream.in/admin/api/get_popup_message.php',
      );
      debugPrint('Fetching popup message from: $url');

      final response = await http.get(url);
      debugPrint('API Response status: ${response.statusCode}');
      debugPrint('API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint('Decoded JSON: $jsonData');

        if (jsonData['status'] == 'success') {
          final messageData = jsonData['data'];
          debugPrint('Message data: $messageData');
          return PopupMessage.fromJson(messageData);
        } else {
          debugPrint('API returned non-success status: ${jsonData['status']}');
        }
      } else {
        debugPrint('API request failed with status: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching popup message: $e');
      return null;
    }
  }
}
