import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/item_model.dart';
import '../../theme/app_theme.dart';
import 'item_details_screen.dart';
import '../widgets/universal_image.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Gear'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/add_item'),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Item>>(
        stream: context.read<FirestoreService>().getMyListings(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ListingCard(item: item);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          const Text(
            'No items listed yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Start earning by listing your equipment.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add_item'),
            icon: const Icon(Icons.add),
            label: const Text('Add New Listing'),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Item item;
  const _ListingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item))),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'item_${item.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: UniversalImage(imageUrl: item.imageUrl, width: 90, height: 90, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${item.pricePerDay.toStringAsFixed(0)} EGP / day', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _StatusChip(isRented: item.isRented),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 22),
                onPressed: () => _confirmDelete(context, item.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Listing?'),
        content: const Text('Are you sure you want to permanently remove this item from your listings?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Remove', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<FirestoreService>().deleteItem(id);
    }
  }
}

class _StatusChip extends StatelessWidget {
  final bool isRented;
  const _StatusChip({required this.isRented});

  @override
  Widget build(BuildContext context) {
    final color = isRented ? AppTheme.secondaryColor : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        isRented ? 'Currently Rented' : 'Available',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
