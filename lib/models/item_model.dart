class Item {
  final String id;
  final String title;
  final String description;
  final double pricePerDay;
  final String imageUrl;
  final String ownerId;
  final int rentalDuration;
  final String category;
  final bool isRented;
  final String? renterId;
  final DateTime createdAt;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.pricePerDay,
    required this.rentalDuration,
    required this.imageUrl,
    required this.ownerId,
    required this.category,
    required this.createdAt,
    this.isRented = false,
    this.renterId,
  });

  // Placeholder for Firestore conversions
}
