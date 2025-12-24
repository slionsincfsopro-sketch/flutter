import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import 'my_listings_screen.dart';
import 'rental_history_screen.dart';
import 'settings_screen.dart';
import 'requests_screen.dart';
import 'admin_screen.dart';

import 'package:image_picker/image_picker.dart';
import '../../utils/image_utils.dart';
import '../widgets/universal_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        setState(() => _isLoading = true);
        final base64String = await ImageUtils.fileToBase64(image);
        if (base64String != null && mounted) {
          await context.read<AuthService>().updateProfile(photoUrl: base64String);
        }
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateName() async {
     if (_nameController.text.trim().isEmpty) return;
     setState(() => _isLoading = true);
     try {
       await context.read<AuthService>().updateProfile(name: _nameController.text.trim());
       setState(() => _isEditingName = false);
     } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
     } finally {
        if (mounted) setState(() => _isLoading = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthService>().signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Premium Profile Header
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor.withOpacity(0.2), AppTheme.secondaryColor.withOpacity(0.2)],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: ClipOval(
                        child: Consumer<AuthService>(
                          builder: (context, auth, _) {
                            final uid = auth.currentUser?.uid;
                            if (uid == null) return const Icon(Icons.person, size: 50);

                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                              builder: (context, snapshot) {
                                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                                final photoUrl = userData?['photoUrl'] as String?;
                                
                                if (photoUrl != null && photoUrl.isNotEmpty) {
                                  return UniversalImage(imageUrl: photoUrl, fit: BoxFit.cover, width: 110, height: 110);
                                }
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.person, size: 50, color: Colors.grey)
                                );
                              }
                            );
                          }
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Positioned.fill(
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Name & Email with Animation
            Consumer<AuthService>(
              builder: (context, auth, _) {
                 final user = auth.currentUser;
                 if (!_isEditingName) {
                    _nameController.text = user?.displayName ?? '';
                 }

                 return AnimatedSwitcher(
                   duration: const Duration(milliseconds: 300),
                   child: _isEditingName 
                    ? Padding(
                        key: const ValueKey('editing'),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                autofocus: true,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(hintText: 'Your name'),
                                onSubmitted: (_) => _updateName(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(onPressed: _updateName, icon: const Icon(Icons.check_rounded)),
                            IconButton.filledTonal(onPressed: () => setState(() => _isEditingName = false), icon: const Icon(Icons.close_rounded)),
                          ],
                        ),
                      )
                    : Column(
                        key: const ValueKey('viewing'),
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isEditingName = true),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(user?.displayName ?? 'User', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24)),
                                const SizedBox(width: 8),
                                const Icon(Icons.edit_rounded, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                          Text(user?.email ?? 'No Email', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                 );
              }
            ),
            const SizedBox(height: 40),
            
            // Modern Stats Grid
            StreamBuilder<bool>(
              stream: context.read<AuthService>().isAdminStream(),
              builder: (context, snapshot) {
                final isAdmin = snapshot.data ?? false;
                if (isAdmin) return const SizedBox.shrink();
                
                return Consumer<AuthService>(
                  builder: (context, auth, _) {
                    final uid = auth.currentUser?.uid;
                    if (uid == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StreamBuilder<List<dynamic>>(
                                stream: context.read<FirestoreService>().getMyListings(uid),
                                builder: (context, snapshot) {
                                  return _buildStatCard(
                                    context, 
                                    '${snapshot.data?.length ?? 0}', 
                                    'My Listings', 
                                    Icons.list_alt_rounded,
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen())),
                                  );
                                }
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StreamBuilder<List<dynamic>>(
                                stream: context.read<FirestoreService>().getRentalHistory(uid),
                                builder: (context, snapshot) {
                                  return _buildStatCard(
                                    context, 
                                    '${snapshot.data?.length ?? 0}', 
                                    'Items Rented', 
                                    Icons.history_rounded,
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalHistoryScreen())),
                                  );
                                }
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    );
                  }
                );
              }
            ),
            
            // Premium Menu
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  StreamBuilder<bool>(
                    stream: context.read<AuthService>().isAdminStream(),
                    builder: (context, snapshot) {
                      final isAdmin = snapshot.data ?? false;
                      if (isAdmin) return const SizedBox.shrink();
                      
                      return Column(
                        children: [
                          _buildMenuItem(context, Icons.inbox_rounded, 'Rental Requests', () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestsScreen()));
                          }),
                          const Divider(indent: 60, height: 1),
                        ],
                      );
                    }
                  ),
                  _buildMenuItem(context, Icons.settings_rounded, 'General Settings', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.all(12),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28, color: AppTheme.textPrimary)),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
