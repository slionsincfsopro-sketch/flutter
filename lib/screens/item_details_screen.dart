import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../models/item_model.dart';
import '../widgets/universal_image.dart';

class ItemDetailsScreen extends StatelessWidget {
  final Item item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Cinematic App Bar & Image
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton.filledTonal(
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.9)),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'item_${item.id}',
                child: UniversalImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 26),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.category,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (item.isRented ? AppTheme.errorColor : AppTheme.secondaryColor).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.isRented ? 'Already Rented' : 'Available',
                              style: TextStyle(
                                color: item.isRented ? AppTheme.errorColor : AppTheme.secondaryColor, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 12
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats Row
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppTheme.secondaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Listed on: ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(Icons.timer_outlined, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 4),
                      Text('Max: ${item.rentalDuration} days', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(height: 1),
                  ),
                  
                  // Description
                  Text(
                    'About this equipment',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary, height: 1.6),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Owner Info
                  Text(
                    'Owner info',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(item.ownerId).snapshots(),
                    builder: (context, snapshot) {
                      final userData = snapshot.data?.data() as Map<String, dynamic>?;
                      final photoUrl = userData?['photoUrl'] as String?;
                      final name = userData?['name'] as String? ?? 'Owner';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            ClipOval(
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? UniversalImage(imageUrl: photoUrl, width: 56, height: 56, fit: BoxFit.cover)
                                  : Container(
                                      width: 56, 
                                      height: 56, 
                                      color: Colors.grey.shade200, 
                                      child: const Icon(Icons.person, color: Colors.grey)
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const Text('Verified Provider', style: TextStyle(color: AppTheme.secondaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 120), // Padding for bottom sheet
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: StreamBuilder<bool>(
          stream: context.read<AuthService>().isAdminStream(),
          builder: (context, snapshot) {
            final auth = context.read<AuthService>();
            final isAdmin = snapshot.data ?? false;
            final isOwner = auth.currentUser?.uid == item.ownerId;
            final canBook = !item.isRented; 
            
            return Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rental Price', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      '${item.pricePerDay.toStringAsFixed(0)} EGP/day',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                if (!isAdmin) ...[
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canBook && !isOwner ? () => _handleRequest(context) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.isRented || isOwner ? Colors.grey : AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        item.isRented ? 'Already Rented' : (isOwner ? 'My Listing' : 'Book Now'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }
        ),
      ),
    );
  }

  Future<void> _handleRequest(BuildContext context) async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: auth.currentUser?.displayName);
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Booking',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Row(
                children: [
                  Icon(Icons.assignment_ind_outlined, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text('Confirm Booking'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Please provide your contact details for the owner to reach you.'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v!.isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '01xxxxxxxxx',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Phone number required';
                          final regExp = RegExp(r'^01[0125][0-9]{8}$');
                          if (!regExp.hasMatch(v)) return 'Enter a valid Egyptian phone number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery/Pickup Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        maxLines: 2,
                        validator: (v) => v!.isEmpty ? 'Address required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await context.read<FirestoreService>().createRequest(
                          itemId: item.id,
                          ownerId: item.ownerId,
                          renterId: auth.currentUser!.uid,
                          renterName: nameController.text.trim(),
                          renterPhone: phoneController.text.trim(),
                          renterAddress: addressController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request sent successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context); // Go back to Home
                        }
                      } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
                           );
                         }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
