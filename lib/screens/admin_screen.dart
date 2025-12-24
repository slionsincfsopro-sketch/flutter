import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../models/request_model.dart';
import '../widgets/universal_image.dart';
import 'main_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _AdminDashboardHome(),
    const _AdminAllItems(),
    const _AdminAllRequests(),
    const _AdminAllUsers(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch to User View',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Items'),
          NavigationDestination(icon: Icon(Icons.list_alt_rounded), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), label: 'Users'),
        ],
      ),
    );
  }
}

class _AdminDashboardHome extends StatelessWidget {
  const _AdminDashboardHome();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Overview', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard(context, 'Total Items', 'items', Icons.inventory_2, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard(context, 'Active Rentals', 'items', Icons.shopping_bag, Colors.orange, query: (ref) => ref.where('isRented', isEqualTo: true)),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(context, 'Total Requests', 'requests', Icons.compare_arrows, Colors.purple),
          const SizedBox(height: 32),
          Text('Recent Activity', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          // Simple list of recent requests
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('requests').orderBy('createdAt', descending: true).limit(5).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.notifications_none_rounded)),
                    title: Text('New request for item ${data['itemId']}'),
                    subtitle: Text('Status: ${data['status']}'),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.errorColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Danger Zone',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.errorColor),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will permanently delete ALL users, items, and requests from the database.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _confirmGlobalReset(context),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('RESET ALL DATA (SYSTEM WIPE)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmItemsWipe(context),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('WIPE ITEMS ONLY'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmGlobalReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ PERMANENT RESET?'),
        content: const Text('Are you sure you want to delete EVERY record in the database (Users, Items, Requests)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('YES, RESET EVERYTHING', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final auth = context.read<AuthService>();
      final firestore = context.read<FirestoreService>();
      final adminUid = auth.currentUser?.uid;
      
      if (adminUid != null) {
        try {
          await firestore.resetAllData(adminUid);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All data has been reset successfully.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to reset: $e'), backgroundColor: AppTheme.errorColor),
            );
          }
        }
      }
    }
  }

  void _confirmItemsWipe(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ WIPE ITEMS ONLY?'),
        content: const Text('This will delete ALL product listings but keep user accounts. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('WIPE ITEMS', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<FirestoreService>().wipeAllItems();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All items have been removed.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error wiping items: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String collection, IconData icon, Color color, {Query Function(Query)? query}) {
    Query ref = FirebaseFirestore.instance.collection(collection);
    if (query != null) ref = query(ref);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: ref.snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                return Text('$count', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold));
              },
            ),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _AdminAllItems extends StatelessWidget {
  const _AdminAllItems();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return StreamBuilder<List<Item>>(
      stream: firestore.getItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: UniversalImage(imageUrl: item.imageUrl, width: 48, height: 48, fit: BoxFit.cover),
              ),
              title: Text(item.title),
              subtitle: Text(item.category),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                onPressed: () => _confirmDelete(context, item.id),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('This will permanently remove the item from the system.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
    if (confirmed == true) {
      context.read<FirestoreService>().deleteItem(id);
    }
  }
}

class _AdminAllRequests extends StatelessWidget {
  const _AdminAllRequests();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RentalRequest>>(
      stream: context.read<FirestoreService>().getAllRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!;
        
        if (requests.isEmpty) {
          return const Center(child: Text('No requests found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: UniversalImage(imageUrl: request.inputItemImage, width: 48, height: 48, fit: BoxFit.cover),
                ),
                title: Text(request.inputItemName ?? 'Unknown Item'),
                subtitle: Text(
                  'Owner: ${request.ownerName}\n'
                  'Renter: ${request.renterName}\n'
                  'Status: ${request.status.toUpperCase()}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Request?'),
                          content: const Text('This will remove this record forever.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        context.read<FirestoreService>().deleteRequest(request.id);
                      }
                    } else {
                      context.read<FirestoreService>().updateRequestStatus(request.id, val);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pending', child: Row(children: [Icon(Icons.timer_outlined, size: 18), SizedBox(width: 8), Text('Set Pending')])),
                    const PopupMenuItem(value: 'approved', child: Row(children: [Icon(Icons.check_circle_outline, size: 18, color: Colors.green), SizedBox(width: 8), Text('Approve')])),
                    const PopupMenuItem(value: 'rejected', child: Row(children: [Icon(Icons.cancel_outlined, size: 18, color: Colors.orange), SizedBox(width: 8), Text('Reject / Cancel')])),
                    const PopupMenuItem(value: 'completed', child: Row(children: [Icon(Icons.done_all_rounded, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Mark Completed')])),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever, size: 18, color: AppTheme.errorColor), SizedBox(width: 8), Text('Delete Permanently', style: TextStyle(color: AppTheme.errorColor))])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminAllUsers extends StatelessWidget {
  const _AdminAllUsers();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            final isMe = id == context.read<AuthService>().currentUser?.uid;
            
            return ListTile(
              leading: ClipOval(
                child: UniversalImage(imageUrl: data['photoUrl'], width: 40, height: 40, fit: BoxFit.cover),
              ),
              title: Text(data['name'] ?? 'No Name'),
              subtitle: Text(data['email'] ?? 'No Email'),
              trailing: isMe 
                ? const Chip(label: Text('You', style: TextStyle(fontSize: 10)))
                : IconButton(
                    icon: const Icon(Icons.person_remove_outlined, color: AppTheme.errorColor),
                    onPressed: () => _confirmDeleteUser(context, id, data['name'] ?? 'User'),
                  ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to remove $name? This will NOT delete their items or requests unless you do that manually.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
    if (confirmed == true) {
      FirebaseFirestore.instance.collection('users').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User $name deleted.')));
    }
  }
}
