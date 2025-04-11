import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/artist_item.dart';

class ProfileService {
  static const String apiKey = 'MOHAMMADASKERYMALIKFROMNOWLARI';
  static const String baseUrl = 'https://algodream.in/admin/api';

  static Future<List<ArtistItem>> getProfilesByCategory(String category) async {
    try {
      print('Fetching profiles for category: $category');
      final url = Uri.parse(
        '$baseUrl/get_profiles_by_category.php?api_key=$apiKey&category=$category',
      );

      print('API URL: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print('API Response: ${response.body}');
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> profilesData = jsonData['data'];
          print('Received ${profilesData.length} profiles from API');

          final profiles =
              profilesData.map((item) => ArtistItem.fromJson(item)).toList();

          // Log each profile for debugging
          for (var profile in profiles) {
            print(
              'Profile: ${profile.name}, Category: ${profile.category}, Image: ${profile.imageUrl}',
            );
          }

          return profiles;
        } else {
          print('API error: ${jsonData['message']}');
          return [];
        }
      } else {
        print('Failed to load profiles: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching profiles: $e');
      return [];
    }
  }

  // New method to fetch random profiles
  static Future<List<ArtistItem>> getRandomProfiles() async {
    try {
      print('Fetching random profiles');
      final url = Uri.parse('$baseUrl/get_random_profiles.php?api_key=$apiKey');

      print('Random Profiles API URL: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print('Random Profiles API Response: ${response.body}');
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> profilesData = jsonData['data'];
          print('Received ${profilesData.length} random profiles from API');

          final profiles =
              profilesData.map((item) => ArtistItem.fromJson(item)).toList();

          // Log each profile for debugging
          for (var profile in profiles) {
            print(
              'Random Profile: ${profile.name}, Category: ${profile.category}, Image: ${profile.imageUrl}',
            );
          }

          return profiles;
        } else {
          print('API error: ${jsonData['message']}');
          return [];
        }
      } else {
        print('Failed to load random profiles: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching random profiles: $e');
      return [];
    }
  }
}
