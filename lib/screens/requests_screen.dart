import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'payment_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/request_model.dart';
import '../../models/item_model.dart';
import '../../theme/app_theme.dart';
import '../widgets/universal_image.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  void _confirmPurgeUsers(BuildContext context) async {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final adminUid = auth.currentUser?.uid;

    if (adminUid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Purge All Users?'),
        content: const Text('This will delete all users from the database except your admin account. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('YES, PURGE ALL', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await firestore.deleteOnlyUsers(adminUid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All users purged successfully.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to purge: $e'), backgroundColor: AppTheme.errorColor));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return StreamBuilder<bool>(
      stream: context.read<AuthService>().isAdminStream(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;
        
        if (isAdmin) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: const Text('System All Activity'),
              actions: [
                TextButton.icon(
                  onPressed: () => _confirmPurgeUsers(context),
                  icon: const Icon(Icons.person_remove_outlined, color: AppTheme.errorColor),
                  label: const Text('Purge Users', style: TextStyle(color: AppTheme.errorColor)),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: const _AdminAllRequestsTab(),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: const Text('Rentals'),
              bottom: TabBar(
                indicatorColor: AppTheme.primaryColor,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Received'),
                  Tab(text: 'Sent'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _IncomingRequestsTab(uid: uid),
                _OutgoingRequestsTab(uid: uid),
              ],
            ),
          ),
        );
      }
    );
  }
}

class _AdminAllRequestsTab extends StatelessWidget {
  const _AdminAllRequestsTab();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    
    return StreamBuilder<List<RentalRequest>>(
      stream: firestore.getAllRequests(),
      builder: (context, requestSnapshot) {
        return StreamBuilder<List<Item>>(
          stream: firestore.getAllItems(),
          builder: (context, itemSnapshot) {
            if (!requestSnapshot.hasData || !itemSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final requests = requestSnapshot.data!;
            final items = itemSnapshot.data!;

            // Combine and sort by date
            final List<Map<String, dynamic>> combinedActivity = [
              ...requests.map((r) => {'type': 'request', 'data': r, 'date': r.createdAt}),
              ...items.map((i) => {'type': 'item', 'data': i, 'date': i.createdAt}),
            ];
            
            combinedActivity.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

            if (combinedActivity.isEmpty) {
              return _buildEmptyState('No system activity yet', Icons.analytics_outlined);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: combinedActivity.length,
              itemBuilder: (context, index) {
                final activity = combinedActivity[index];
                if (activity['type'] == 'request') {
                  final req = activity['data'] as RentalRequest;
                  return _RequestCard(
                    req: req,
                    isIncoming: true,
                    actions: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Row(
                          children: [
                            const Icon(Icons.person_pin_outlined, size: 14, color: AppTheme.secondaryColor),
                            const SizedBox(width: 4),
                            Text('Owner: ${req.ownerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            const Icon(Icons.history, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${req.createdAt.hour}:${req.createdAt.minute}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  );
                } else {
                  final item = activity['data'] as Item;
                  return _ItemActivityCard(item: item);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _ItemActivityCard extends StatelessWidget {
  final Item item;
  const _ItemActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: UniversalImage(imageUrl: item.imageUrl, width: 64, height: 64, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('NEW LISTING', style: TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Text('${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Category: ${item.category} • ${item.pricePerDay} EGP/Day', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(item.ownerId).snapshots(),
                  builder: (context, snapshot) {
                    final name = (snapshot.data?.data() as Map<String, dynamic>?)?['name'] ?? 'Owner';
                    return Text('Listed by: $name', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w600));
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingRequestsTab extends StatelessWidget {
  final String uid;
  const _IncomingRequestsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RentalRequest>>(
      stream: context.read<FirestoreService>().getIncomingRequests(uid),
      builder: (context, snapshot) {
         if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
         if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
         if (snapshot.data!.isEmpty) return _buildEmptyState('No incoming requests yet', Icons.inbox_outlined);

         return ListView.builder(
           padding: const EdgeInsets.all(20),
           itemCount: snapshot.data!.length,
           itemBuilder: (context, index) {
             final req = snapshot.data![index];
             return _RequestCard(
               req: req,
               isIncoming: true,
                actions: req.status == 'pending' 
                 ? Row(
                     children: [
                       Expanded(
                         child: OutlinedButton(
                           onPressed: () => context.read<FirestoreService>().updateRequestStatus(req.id, 'rejected'),
                           style: OutlinedButton.styleFrom(
                             foregroundColor: AppTheme.errorColor,
                             side: const BorderSide(color: AppTheme.errorColor),
                             padding: const EdgeInsets.symmetric(vertical: 12),
                           ),
                           child: const Text('Reject'),
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: ElevatedButton(
                           onPressed: () => context.read<FirestoreService>().updateRequestStatus(req.id, 'approved'),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppTheme.secondaryColor,
                             padding: const EdgeInsets.symmetric(vertical: 12),
                           ),
                           child: const Text('Approve'),
                         ),
                       ),
                     ],
                   )
                 : Align(
                     alignment: Alignment.centerRight,
                     child: TextButton.icon(
                       onPressed: () => _confirmDelete(context, req.id),
                       icon: const Icon(Icons.delete_outline_rounded, size: 18),
                       label: const Text('Remove from List'),
                       style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
                     ),
                   ),
              );
            },
          );
       },
     );
   }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Request?'),
        content: const Text('This will hide the request from your list. This action cannot be undone.'),
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
      await context.read<FirestoreService>().deleteRequest(id);
    }
  }
}

class _OutgoingRequestsTab extends StatelessWidget {
  final String uid;
  const _OutgoingRequestsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RentalRequest>>(
      stream: context.read<FirestoreService>().getOutgoingRequests(uid),
      builder: (context, snapshot) {
         if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
         if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
         if (snapshot.data!.isEmpty) return _buildEmptyState('You haven\'t sent any requests', Icons.send_outlined);

         return ListView.builder(
           padding: const EdgeInsets.all(20),
           itemCount: snapshot.data!.length,
           itemBuilder: (context, index) {
             final req = snapshot.data![index];
             return _RequestCard(
               req: req,
               isIncoming: false,
                actions: req.status == 'approved'
                 ? ElevatedButton(
                     onPressed: () => Navigator.push(
                       context,
                       MaterialPageRoute(builder: (_) => PaymentScreen(requestId: req.id, itemId: req.itemId, renterId: req.renterId)),
                     ),
                     style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                     child: const Text('Pay Now'),
                   )
                 : Align(
                     alignment: Alignment.centerRight,
                     child: TextButton.icon(
                       onPressed: () => _confirmDelete(context, req.id),
                       icon: Icon(req.status == 'pending' ? Icons.close_rounded : Icons.delete_outline_rounded, size: 18),
                       label: Text(req.status == 'pending' ? 'Cancel Request' : 'Remove from List'),
                       style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
                     ),
                   ),
             );
           },
         );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel Request', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<FirestoreService>().deleteRequest(id);
    }
  }
}

class _RequestCard extends StatelessWidget {
  final RentalRequest req;
  final bool isIncoming;
  final Widget? actions;

  const _RequestCard({required this.req, required this.isIncoming, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: UniversalImage(imageUrl: req.inputItemImage, width: 64, height: 64, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.inputItemName ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (isIncoming) 
                        Text('Requested by: ${req.renterName}', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      if (isIncoming) ...[
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(req.renterPhone ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(child: Text(req.renterAddress ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatusBadge(status: req.status),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Requested: ${req.createdAt.day}/${req.createdAt.month}/${req.createdAt.year}',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                              ),
                              if (req.approvedAt != null)
                                Text(
                                  'Approved: ${req.approvedAt!.day}/${req.approvedAt!.month}/${req.approvedAt!.year}',
                                  style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (actions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: actions,
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'approved') color = AppTheme.secondaryColor;
    if (status == 'pending') color = AppTheme.accentColor;
    if (status == 'rejected') color = AppTheme.errorColor;
    if (status == 'paid') color = Colors.blue;
    if (status == 'completed') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

Widget _buildEmptyState(String msg, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey.shade200),
        const SizedBox(height: 16),
        Text(msg, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

Widget _buildErrorState(String error) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text('Service Error: $error', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.errorColor)),
    ),
  );
}
