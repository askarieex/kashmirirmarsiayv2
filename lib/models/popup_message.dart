// Create this file at lib/models/popup_message.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PopupMessage {
  final bool display;
  final String message;

  PopupMessage({required this.display, required this.message});

  factory PopupMessage.fromJson(Map<String, dynamic> json) {
    return PopupMessage(
      display: json['display'] ?? false,
      message: json['message'] ?? '',
    );
  }

  static Future<PopupMessage?> fetchFromApi() async {
    try {
      final url = Uri.parse(
        'https://algodream.in/admin/api/get_popup_message.php',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          final messageData = jsonData['data'];
          return PopupMessage.fromJson(messageData);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching popup message: $e');
      return null;
    }
  }
}
