class ArtistItem {
  final String name;
  final String imageUrl;
  final String category;
  final String uniqueId;

  ArtistItem({
    required this.name,
    required this.imageUrl,
    this.category = '',
    this.uniqueId = '',
  });
}
