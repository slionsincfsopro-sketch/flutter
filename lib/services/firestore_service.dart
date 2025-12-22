import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> addItem(Item item) async {
    await _db.collection('items').add({
      'title': item.title,
      'description': item.description,
      'pricePerDay': item.pricePerDay,
      'imageUrl': item.imageUrl,
      'ownerId': item.ownerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rentItem(String itemId) async {
    // Simple implementation: Mark item as rented.
    // In a full app, this would use a subcollection 'bookings' and check dates.
    // For now, let's just update a status field.
    await _db.collection('items').doc(itemId).update({
      'isRented': true,
      'rentedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Item>> getItems() {
    return _db.collection('items').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Item(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          ownerId: data['ownerId'] ?? '',
        );
      }).toList();
    });
  }

  Future<void> seedMockData() async {
    final snapshot = await _db.collection('items').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final mockItems = [
        Item(id: '', title: 'Canon EOS R5', description: 'Professional mirrorless camera with 8K video.', pricePerDay: 85, imageUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32', ownerId: 'system'),
        Item(id: '', title: 'DJI Mavic 3', description: 'Advanced drone with Hasselblad camera.', pricePerDay: 120, imageUrl: 'https://images.unsplash.com/photo-1473968512647-3e447244af8f', ownerId: 'system'),
        Item(id: '', title: 'Zoom H6 Recorder', description: 'Portable 6-track audio recorder.', pricePerDay: 25, imageUrl: 'https://images.unsplash.com/photo-1590845947698-8924d7409b56', ownerId: 'system'),
        Item(id: '', title: 'GoPro Hero 11', description: 'Action camera with stabilization.', pricePerDay: 30, imageUrl: 'https://images.unsplash.com/photo-1564466013183-bbe9616e36d6', ownerId: 'system'),
      ];
      for (var item in mockItems) {
        await addItem(item);
      }
    }
  }
}
