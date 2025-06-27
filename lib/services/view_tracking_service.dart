import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewTrackingService {
  static const String apiKey = 'MOHAMMADASKERYMALIKFROMNOWLARI';
  static const String baseUrl = 'https://algodream.in/admin/api';

  // Track Noha audio view
  static Future<Map<String, dynamic>> incrementNohaView(String nohaId) async {
    try {
      final url = Uri.parse(
        '$baseUrl/update_noha_view.php?api_key=$apiKey&noha_id=$nohaId',
      );

      print('🔄 Calling Noha API: $url');
      final response = await http.get(url);
      print('📡 Noha API Response Status: ${response.statusCode}');
      print('📡 Noha API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('✅ Noha view updated for ID $nohaId: ${jsonData['message']}');

        return {
          'success': jsonData['status'] == 'success',
          'views': jsonData['data']?['views'] ?? 0,
          'message': jsonData['message'] ?? 'Unknown response',
        };
      } else {
        print('Failed to update Noha view: HTTP ${response.statusCode}');
        return {
          'success': false,
          'views': 0,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error updating Noha view: $e');
      return {'success': false, 'views': 0, 'message': 'Network Error: $e'};
    }
  }

  // Track Marsiya audio view
  static Future<Map<String, dynamic>> incrementMarsiyaView(
    String audioId,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/update_marsiya_view.php?api_key=$apiKey&audio_id=$audioId',
      );

      print('🔄 Calling Marsiya API: $url');
      final response = await http.get(url);
      print('📡 Marsiya API Response Status: ${response.statusCode}');
      print('📡 Marsiya API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('✅ Marsiya view updated for ID $audioId: ${jsonData['message']}');

        return {
          'success': jsonData['status'] == 'success',
          'views': jsonData['data']?['views'] ?? 0,
          'message': jsonData['message'] ?? 'Unknown response',
        };
      } else {
        print('Failed to update Marsiya view: HTTP ${response.statusCode}');
        return {
          'success': false,
          'views': 0,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error updating Marsiya view: $e');
      return {'success': false, 'views': 0, 'message': 'Network Error: $e'};
    }
  }

  // Track Profile view
  static Future<Map<String, dynamic>> incrementProfileView(
    String profileId,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/update_profile_view.php?api_key=$apiKey&profile_id=$profileId',
      );

      print('🔄 Calling Profile API: $url');
      final response = await http.get(url);
      print('📡 Profile API Response Status: ${response.statusCode}');
      print('📡 Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print(
          '✅ Profile view updated for ID $profileId: ${jsonData['message']}',
        );

        return {
          'success': jsonData['status'] == 'success',
          'views':
              jsonData['data']?['total_views'] ??
              0, // Profile API returns 'total_views'
          'message': jsonData['message'] ?? 'Unknown response',
        };
      } else {
        print('Failed to update Profile view: HTTP ${response.statusCode}');
        return {
          'success': false,
          'views': 0,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error updating Profile view: $e');
      return {'success': false, 'views': 0, 'message': 'Network Error: $e'};
    }
  }

  // Get Marsiya audio recommendations
  static Future<List<dynamic>> getMarsiyaRecommendations() async {
    try {
      final url = Uri.parse(
        '$baseUrl/get_marsiya_recommendations.php?api_key=$apiKey',
      );

      print('🔄 Calling Marsiya Recommendations API: $url');
      final response = await http.get(url);
      print('📡 Recommendations API Response Status: ${response.statusCode}');
      print('📡 Recommendations API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          print(
            '✅ Fetched ${jsonData['data']?.length ?? 0} marsiya recommendations',
          );
          return jsonData['data'] ?? [];
        } else {
          print('❌ API Error getting recommendations: ${jsonData['message']}');
          return [];
        }
      } else {
        print('❌ Failed to get recommendations: HTTP ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting marsiya recommendations: $e');
      return [];
    }
  }

  // Helper method to format view count display
  static String formatViewCount(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    } else {
      return viewCount.toString();
    }
  }

  // Batch update views (for multiple items viewed together)
  static Future<void> batchUpdateViews({
    List<String>? nohaIds,
    List<String>? marsiyaIds,
    List<String>? profileIds,
  }) async {
    // Update Noha views
    if (nohaIds != null && nohaIds.isNotEmpty) {
      for (String nohaId in nohaIds) {
        await incrementNohaView(nohaId);
        // Small delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Update Marsiya views
    if (marsiyaIds != null && marsiyaIds.isNotEmpty) {
      for (String marsiyaId in marsiyaIds) {
        await incrementMarsiyaView(marsiyaId);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Update Profile views
    if (profileIds != null && profileIds.isNotEmpty) {
      for (String profileId in profileIds) {
        await incrementProfileView(profileId);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}
