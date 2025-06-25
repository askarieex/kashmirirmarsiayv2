import 'package:flutter/material.dart';

// Result types for search
enum SearchResultType { marsiya, noha, audio, profile }

// Model for search results
class SearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final SearchResultType type;
  final String? imageUrl;
  final Map<String, dynamic> data; // Additional data for the result

  SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.imageUrl,
    required this.data,
  });
}

class AppSearchService {
  // Search across the entire app
  static Future<List<SearchResult>> searchAll(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final normalizedQuery = query.toLowerCase().trim();

    // Perform searches in parallel for better performance
    final results = await Future.wait([
      searchMarsiya(normalizedQuery),
      searchNoha(normalizedQuery),
      searchAudio(normalizedQuery),
      searchProfiles(normalizedQuery),
    ]);

    // Flatten the results
    return results.expand((x) => x).toList();
  }

  // Search in marsiya content
  static Future<List<SearchResult>> searchMarsiya(
    String normalizedQuery,
  ) async {
    // This would be replaced with actual API calls or database queries
    // For now, just returning dummy data

    await Future.delayed(
      const Duration(milliseconds: 300),
    ); // Simulate network delay

    // Mock results
    final List<SearchResult> results = [];

    // Add your marsiya search implementation here
    // Example:
    if ('marsiya'.contains(normalizedQuery)) {
      results.add(
        SearchResult(
          id: 'marsiya1',
          title: 'Sample Marsiya',
          subtitle: 'Author: Sample Author',
          type: SearchResultType.marsiya,
          data: {'author': 'Sample Author', 'language': 'Kashmiri'},
        ),
      );
    }

    return results;
  }

  // Search in noha content
  static Future<List<SearchResult>> searchNoha(String normalizedQuery) async {
    await Future.delayed(
      const Duration(milliseconds: 250),
    ); // Simulate network delay

    // Mock results
    final List<SearchResult> results = [];

    // Add your noha search implementation here
    // Example:
    if ('noha'.contains(normalizedQuery)) {
      results.add(
        SearchResult(
          id: 'noha1',
          title: 'Sample Noha',
          subtitle: 'By: Sample Artist',
          type: SearchResultType.noha,
          data: {'artist': 'Sample Artist', 'year': '2023'},
        ),
      );
    }

    return results;
  }

  // Search in audio content
  static Future<List<SearchResult>> searchAudio(String normalizedQuery) async {
    await Future.delayed(
      const Duration(milliseconds: 200),
    ); // Simulate network delay

    // Mock results
    final List<SearchResult> results = [];

    // Add your audio search implementation here
    // Example:
    if ('audio'.contains(normalizedQuery)) {
      // Add a marsiya audio example
      results.add(
        SearchResult(
          id: 'audio1',
          title: 'Sample Marsiya Audio',
          subtitle: 'Duration: 5:30',
          type: SearchResultType.audio,
          data: {
            'duration': '5:30',
            'fileSize': '8.2 MB',
            'contentType': 'marsiya',
          },
        ),
      );

      // Add a noha audio example
      results.add(
        SearchResult(
          id: 'audio2',
          title: 'Sample Noha Audio',
          subtitle: 'Duration: 4:15',
          type: SearchResultType.audio,
          data: {
            'duration': '4:15',
            'fileSize': '7.4 MB',
            'contentType': 'noha',
          },
        ),
      );
    }

    return results;
  }

  // Search in profiles
  static Future<List<SearchResult>> searchProfiles(
    String normalizedQuery,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 150),
    ); // Simulate network delay

    // Mock results
    final List<SearchResult> results = [];

    // Add your profile search implementation here
    // Example:
    if ('profile'.contains(normalizedQuery)) {
      results.add(
        SearchResult(
          id: 'profile1',
          title: 'Sample Profile',
          subtitle: 'Role: Zakir',
          type: SearchResultType.profile,
          imageUrl: 'assets/images/logo.png',
          data: {'role': 'Zakir', 'location': 'Kashmir'},
        ),
      );
    }

    return results;
  }

  // Helper method to navigate to the appropriate screen based on result type
  static void navigateToResult(BuildContext context, SearchResult result) {
    switch (result.type) {
      case SearchResultType.marsiya:
        // Navigate to the full marsiya screen
        Navigator.pushNamed(
          context,
          '/full_marsiya_screen',
          arguments: {'id': result.id, 'title': result.title},
        );
        break;
      case SearchResultType.noha:
        // Navigate to the full noha screen
        Navigator.pushNamed(
          context,
          '/full_noha_screen',
          arguments: {'id': result.id, 'title': result.title},
        );
        break;
      case SearchResultType.audio:
        // For audio results, check what type of content it is
        // and navigate to the appropriate player
        final contentType = result.data['contentType'] ?? 'noha';
        if (contentType == 'marsiya') {
          // Navigate to marsiya audio player
          Navigator.pushNamed(
            context,
            '/marsiya_audio_screen',
            arguments: {'id': result.id, 'title': result.title},
          );
        } else {
          // Navigate to noha audio player
          Navigator.pushNamed(
            context,
            '/noha_audio_screen',
            arguments: {'id': result.id, 'title': result.title},
          );
        }
        break;
      case SearchResultType.profile:
        // Navigate to profile screen
        Navigator.pushNamed(
          context,
          '/view_profile_screen',
          arguments: {'id': result.id},
        );
        break;
    }
  }
}
