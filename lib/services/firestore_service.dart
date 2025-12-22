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
}
