import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recent_search.dart';

class SearchService {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches =
      15; // Maximum number of recent searches to store

  // Get all recent searches
  static Future<List<RecentSearch>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> searchesJson =
        prefs.getStringList(_recentSearchesKey) ?? [];

    return searchesJson
        .map((json) => RecentSearch.fromJson(jsonDecode(json)))
        .toList()
      ..sort(
        (a, b) => b.timestamp.compareTo(a.timestamp),
      ); // Sort by most recent first
  }

  // Save a search query to recent searches
  static Future<void> saveSearch(
    String query,
    String type, {
    String? itemId,
  }) async {
    if (query.trim().isEmpty) return;

    final search = RecentSearch(
      query: query.trim(),
      type: type,
      timestamp: DateTime.now(),
      itemId: itemId,
    );

    final prefs = await SharedPreferences.getInstance();
    final List<String> searchesJson =
        prefs.getStringList(_recentSearchesKey) ?? [];

    // Remove identical searches
    List<RecentSearch> searches =
        searchesJson
            .map((json) => RecentSearch.fromJson(jsonDecode(json)))
            .where(
              (existingSearch) =>
                  existingSearch.query.toLowerCase() != query.toLowerCase(),
            )
            .toList();

    // Add new search
    searches.insert(0, search);

    // Limit to maximum number of searches
    if (searches.length > _maxRecentSearches) {
      searches = searches.sublist(0, _maxRecentSearches);
    }

    // Convert back to JSON strings
    searchesJson.clear();
    searchesJson.addAll(searches.map((search) => jsonEncode(search.toJson())));

    // Save to SharedPreferences
    await prefs.setStringList(_recentSearchesKey, searchesJson);
  }

  // Clear all recent searches
  static Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }

  // Remove a specific search from history
  static Future<void> removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> searchesJson =
        prefs.getStringList(_recentSearchesKey) ?? [];

    List<RecentSearch> searches =
        searchesJson
            .map((json) => RecentSearch.fromJson(jsonDecode(json)))
            .where(
              (existingSearch) =>
                  existingSearch.query.toLowerCase() != query.toLowerCase(),
            )
            .toList();

    // Convert back to JSON strings
    searchesJson.clear();
    searchesJson.addAll(searches.map((search) => jsonEncode(search.toJson())));

    // Save to SharedPreferences
    await prefs.setStringList(_recentSearchesKey, searchesJson);
  }
}
