import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as Math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../models/item_model.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'profile_screen.dart';
import '../widgets/universal_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Cameras', 'Drones', 'Audio', 'Camping', 'Tools', 'Electronics', 'Others'];

  @override
  void initState() {
    super.initState();
    // Seeding logic removed as requested to keep the app clean.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Item>>(
          stream: context.read<FirestoreService>().getItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allItems = snapshot.data ?? [];
            final isEmpty = allItems.isEmpty;

            return FutureBuilder<bool>(
              future: context.read<AuthService>().isAdmin(),
              builder: (context, adminSnapshot) {
                final isAdmin = adminSnapshot.data ?? false;

                return Column(
                  children: [
                    _buildHeader(context),

                    if (isEmpty)
                      const Expanded(
                        child: Center(
                          child: _GlassyAnimatedBanner(),
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search cameras, drills, tents...',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                            suffixIcon: _searchQuery.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded), 
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ) 
                              : null,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      SizedBox(height: 60, child: _buildCategoryList()),
                      const SizedBox(height: 12),
                      _buildMarqueeBanner(),
                      const SizedBox(height: 24),

                      Expanded(
                        child: _buildFilteredGrid(allItems, isAdmin),
                      ),
                    ],
                  ],
                );
              }
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
        },
        label: const Text('New Listing'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 2),
              ),
              child: ClipOval(
                child: Consumer<AuthService>(
                  builder: (context, auth, _) {
                    final uid = auth.currentUser?.uid;
                    if (uid == null) return const CircleAvatar(radius: 28, child: Icon(Icons.person));
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                      builder: (context, snapshot) {
                        final photoUrl = (snapshot.data?.data() as Map<String, dynamic>?)?['photoUrl'] as String?;
                        return UniversalImage(imageUrl: photoUrl, width: 56, height: 56, fit: BoxFit.cover);
                      },
                    );
                  }
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<AuthService>(
            builder: (context, auth, _) {
              final name = auth.currentUser?.displayName?.split(' ').first ?? 'User';
              return Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Welcome, $name! 👋',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color = AppTheme.primaryColor.withOpacity(0.15),
                    ),
                  ),
                  Text(
                    'Welcome, $name! 👋',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: 4),
          Text(
            'Find the perfect tool for your project',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredGrid(List<Item> allItems, bool isAdmin) {
    final filteredItems = allItems.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No items found matching your search', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return Hero(
          tag: 'item_${item.id}',
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context, 
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 600),
                    reverseTransitionDuration: const Duration(milliseconds: 600),
                    pageBuilder: (context, animation, secondaryAnimation) => ItemDetailsScreen(item: item),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
              child: _buildItemCard(context, item, isAdmin),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarqueeBanner() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: const _MarqueeWidget(
          text: 'Rent and list your items easily with us and your life will be easier • Rent and list your items easily with us and your life will be easier • ',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final isSelected = _selectedCategory == cat;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _selectedCategory = cat);
            },
            showCheckmark: false,
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, Item item, bool isAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: UniversalImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item.pricePerDay.toStringAsFixed(0)} EGP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (item.isRented)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                      ),
                      child: const Text(
                        'RENTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(item.ownerId).snapshots(),
                    builder: (context, snapshot) {
                      final userData = snapshot.data?.data() as Map<String, dynamic>?;
                      final name = userData?['name'] as String? ?? 'Owner';
                      final photoUrl = userData?['photoUrl'] as String?;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipOval(
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? UniversalImage(imageUrl: photoUrl, width: 24, height: 24, fit: BoxFit.cover)
                                  : Icon(Icons.person, size: 24, color: Colors.grey.shade400),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name.split(' ').first,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ),
                if (isAdmin)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: () => _confirmAdminDelete(context, item),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Spacer(),
                      const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryColor, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAdminDelete(BuildContext context, Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Action'),
        content: Text('Are you sure you want to delete "${item.title}"? This will affect all system users.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete Permanently', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        await context.read<FirestoreService>().deleteItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted by Admin')),
        );
      }
    }
  }
}

class _GlassyAnimatedBanner extends StatefulWidget {
  const _GlassyAnimatedBanner();

  @override
  _GlassyAnimatedBannerState createState() => _GlassyAnimatedBannerState();
}

class _GlassyAnimatedBannerState extends State<_GlassyAnimatedBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D47A1).withOpacity(0.1 + (_controller.value * 0.1)),
                const Color(0xFF1976D2).withOpacity(0.05 + ((1 - _controller.value) * 0.1)),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF42A5F5).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WavePainter(animation: _controller),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'List your products and let others get their chance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D47A1).withOpacity(0.85),
                          letterSpacing: 0.5,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.5),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final Animation<double> animation;
  _WavePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1976D2).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    final y = size.height * 0.6;
    
    path.moveTo(0, y);
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        y + 10 * Math.sin((i / size.width * 2 * Math.pi) + (animation.value * 2 * Math.pi)),
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MarqueeWidget extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeWidget({required this.text, required this.style});

  @override
  State<_MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<_MarqueeWidget> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        final currentPosition = _scrollController.offset;
        
        if (currentPosition >= maxExtent) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            currentPosition + 3,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(widget.text, style: widget.style),
          ),
        );
      },
    );
  }
}
