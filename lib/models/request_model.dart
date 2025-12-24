import 'package:cloud_firestore/cloud_firestore.dart';

class RentalRequest {
  final String id;
  final String itemId;
  final String renterId;
  final String ownerId;
  final String status; // 'pending', 'approved', 'rejected', 'paid', 'completed'
  final DateTime createdAt;
  final DateTime? approvedAt;
  
  final String? renterName;
  final String? renterPhone;
  final String? renterAddress;
  final String? inputItemName;
  final String? inputItemImage;
  final String? ownerName; // Added for admin visibility

  RentalRequest({
    required this.id,
    required this.itemId,
    required this.renterId,
    required this.ownerId,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.renterName,
    this.renterPhone,
    this.renterAddress,
    this.inputItemName,
    this.inputItemImage,
    this.ownerName,
  });
}
