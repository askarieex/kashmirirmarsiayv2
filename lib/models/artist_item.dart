class ArtistItem {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String? description;
  final String profileImage;
  final int totalViews;

  ArtistItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    this.description,
    required this.profileImage,
    required this.totalViews,
  });

  factory ArtistItem.fromJson(Map<String, dynamic> json) {
    return ArtistItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['profile_image'] ?? '',
      category: json['category'] ?? '',
      description: json['description'],
      profileImage: json['profile_image'] ?? '',
      totalViews: int.tryParse(json['total_views']?.toString() ?? '0') ?? 0,
    );
  }
}
