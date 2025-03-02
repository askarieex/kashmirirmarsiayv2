// Create this file at lib/models/popup_message.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PopupMessage {
  final String message;
  final bool display;

  PopupMessage({required this.message, required this.display});

  factory PopupMessage.fromJson(Map<String, dynamic> json) {
    return PopupMessage(
      message: json['message'] ?? '',
      display: json['display'] == 1 ? true : false,
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
