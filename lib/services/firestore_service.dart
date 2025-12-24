import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../models/request_model.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> addItem(Item item) async {
    await _db.collection('items').add({
      'title': item.title,
      'description': item.description,
      'pricePerDay': item.pricePerDay,
      'rentalDuration': item.rentalDuration,
      'imageUrl': item.imageUrl,
      'ownerId': item.ownerId,
      'category': item.category,
      'isRented': item.isRented,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rentItem(String itemId, String renterId) async {
    await _db.collection('items').doc(itemId).update({
      'isRented': true,
      'renterId': renterId,
      'rentedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(String itemId) async {
    await _db.collection('items').doc(itemId).delete();
  }

  Stream<List<Item>> getItems() {
    return _db.collection('items').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromDoc(doc)).toList();
    });
  }

  Stream<List<Item>> getMyListings(String uid) {
    return _db.collection('items').where('ownerId', isEqualTo: uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromDoc(doc)).toList();
    });
  }

  Stream<List<Item>> getRentalHistory(String uid) {
    return _db.collection('items').where('renterId', isEqualTo: uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromDoc(doc)).toList();
    });
  }

  Future<void> clearFromHistory(String itemId) async {
    await _db.collection('items').doc(itemId).update({
      'renterId': null,
      'isRented': false,
    });
  }

  Item _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Item(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      rentalDuration: data['rentalDuration'] ?? 1,
      imageUrl: data['imageUrl'] ?? '',
      ownerId: data['ownerId'] ?? '',
      category: data['category'] ?? 'Electronics',
      isRented: data['isRented'] ?? false,
      renterId: data['renterId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // --- Data Management ---
  
  Future<void> wipeAllItems() async {
    final snapshot = await _db.collection('items').get();
    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Request System ---

  Future<void> createRequest({
    required String itemId, 
    required String ownerId, 
    required String renterId,
    required String renterName,
    required String renterPhone,
    required String renterAddress,
  }) async {
    await _db.collection('requests').add({
      'itemId': itemId,
      'ownerId': ownerId,
      'renterId': renterId,
      'renterName': renterName,
      'renterPhone': renterPhone,
      'renterAddress': renterAddress,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).delete();
  }

  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    final reqDoc = await _db.collection('requests').doc(requestId).get();
    if (!reqDoc.exists) return;

    final batch = _db.batch();
    batch.update(_db.collection('requests').doc(requestId), {
      'status': newStatus,
      if (newStatus == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
    });

    if (newStatus == 'approved' || newStatus == 'completed') {
      final data = reqDoc.data()!;
      batch.update(_db.collection('items').doc(data['itemId']), {
        'isRented': newStatus == 'approved',
        'renterId': newStatus == 'approved' ? data['renterId'] : null,
      });
    }

    await batch.commit();
  }

  Stream<List<RentalRequest>> getIncomingRequests(String uid) {
    return _db.collection('requests')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = <RentalRequest>[];
          for (var doc in snapshot.docs) {
             requests.add(await _requestFromDoc(doc));
          }
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  Stream<List<RentalRequest>> getOutgoingRequests(String uid) {
    return _db.collection('requests')
        .where('renterId', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = <RentalRequest>[];
          for (var doc in snapshot.docs) {
             requests.add(await _requestFromDoc(doc));
          }
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  Future<RentalRequest> _requestFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    String itemName = 'Unknown Item';
    String itemImage = '';
    String renterName = 'Unknown Renter';
    String ownerName = 'Unknown Owner';
    
    try {
      final itemDoc = await _db.collection('items').doc(data['itemId']).get();
      if (itemDoc.exists) {
        itemName = itemDoc.data()?['title'] ?? 'Unknown';
        itemImage = itemDoc.data()?['imageUrl'] ?? '';
      }
      
      final renterDoc = await _db.collection('users').doc(data['renterId']).get();
      if (renterDoc.exists) {
        renterName = renterDoc.data()?['name'] ?? 'Unknown';
      }

      final ownerDoc = await _db.collection('users').doc(data['ownerId']).get();
      if (ownerDoc.exists) {
        ownerName = ownerDoc.data()?['name'] ?? 'Unknown';
      }
    } catch (_) {}

    return RentalRequest(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      renterId: data['renterId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      inputItemName: itemName,
      renterName: data['renterName'] ?? renterName,
      renterPhone: data['renterPhone'] ?? '',
      renterAddress: data['renterAddress'] ?? '',
      inputItemImage: itemImage,
      ownerName: ownerName,
    );
  }

  // --- Admin Specific Methods ---

  Stream<List<Item>> getAllItems() {
    return _db.collection('items').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromDoc(doc)).toList();
    });
  }

  Stream<List<RentalRequest>> getAllRequests() {
    return _db.collection('requests')
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = <RentalRequest>[];
          for (var doc in snapshot.docs) {
             requests.add(await _requestFromDoc(doc));
          }
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  Future<void> resetAllData(String adminUid) async {
    final batch = _db.batch();
    final requests = await _db.collection('requests').get();
    for (var doc in requests.docs) batch.delete(doc.reference);
    final items = await _db.collection('items').get();
    for (var doc in items.docs) batch.delete(doc.reference);
    final users = await _db.collection('users').get();
    for (var doc in users.docs) {
      if (doc.id != adminUid) batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteOnlyUsers(String adminUid) async {
    final batch = _db.batch();
    final users = await _db.collection('users').get();
    for (var doc in users.docs) {
      // Don't delete the admin!
      if (doc.id != adminUid) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }
}
