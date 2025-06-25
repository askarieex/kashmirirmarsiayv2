import 'dart:convert';

class RecentSearch {
  final String query;
  final String type; // 'audio', 'marsiya', 'noha', etc.
  final DateTime timestamp;
  final String? itemId; // ID of the item if applicable

  RecentSearch({
    required this.query,
    required this.type,
    required this.timestamp,
    this.itemId,
  });

  // Convert to a Map
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'itemId': itemId,
    };
  }

  // Create from a Map
  factory RecentSearch.fromJson(Map<String, dynamic> json) {
    return RecentSearch(
      query: json['query'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      itemId: json['itemId'],
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
