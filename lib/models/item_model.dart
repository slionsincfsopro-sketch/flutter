class Item {
  final String id;
  final String title;
  final String description;
  final double pricePerDay;
  final String imageUrl;
  final String ownerId;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.pricePerDay,
    required this.imageUrl,
    required this.ownerId,
  });

  // Placeholder for Firestore conversions
}
