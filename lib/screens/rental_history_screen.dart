import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/item_model.dart';
import 'item_details_screen.dart';
import '../widgets/universal_image.dart';

class RentalHistoryScreen extends StatelessWidget {
  const RentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return Scaffold(
      appBar: AppBar(title: const Text('Rental History')),
      body: StreamBuilder<List<Item>>(
        stream: context.read<FirestoreService>().getRentalHistory(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No rental history found.'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: SizedBox(
                    width: 60,
                    height: 60,
                    child: UniversalImage(imageUrl: item.imageUrl, fit: BoxFit.cover),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rented for \$${item.pricePerDay}/day'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () async {
                       final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove from History?'),
                          content: const Text('This will hide this item from your rental list.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await context.read<FirestoreService>().clearFromHistory(item.id);
                      }
                    },
                  ),
                  onTap: () {
                     Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item)),
                      );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
