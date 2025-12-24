import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/universal_image.dart';
import '../main_screen.dart';
import '../admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await context.read<AuthService>().signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
          
          // Smooth pulse animation on success
          await _animController.reverse();
          await _animController.forward();
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            // Fetch user role
            final user = context.read<AuthService>().currentUser;
            String targetRoute = 'user';
            
            if (user != null) {
              final isAdmin = await context.read<AuthService>().isAdmin();
              if (isAdmin) {
                targetRoute = 'admin';
              }
            }

            // Professional Page Transition
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String logoPath = 'C:/Users/EL10_gazy/.gemini/antigravity/brain/ebf30410-c0ab-4a61-ab9e-ace7fdc593f8/adawaty_logo_1766545794524.png';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Animated Logo / Profile Reveal
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Center(
                    child: Container(
                      height: 160,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ],
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 2),
                      ),
                      child: ClipOval(
                        child: Consumer<AuthService>(
                          builder: (context, auth, _) {
                            final user = auth.currentUser;
                            
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 800),
                              switchInCurve: Curves.easeInOutExpo,
                              switchOutCurve: Curves.easeInOutExpo,
                              child: (_isSuccess && user != null)
                                  ? StreamBuilder<DocumentSnapshot>(
                                      key: const ValueKey('profile_pic_stream'),
                                      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                                      builder: (context, snapshot) {
                                        final userData = snapshot.data?.data() as Map<String, dynamic>?;
                                        final photoUrl = userData?['photoUrl'] as String?;
                                        
                                        if (photoUrl != null && photoUrl.isNotEmpty) {
                                          return UniversalImage(
                                            imageUrl: photoUrl,
                                            fit: BoxFit.cover,
                                            width: 160,
                                            height: 160,
                                            key: const ValueKey('profile_actual'),
                                          );
                                        }
                                        return _buildLogoFallback(logoPath);
                                      },
                                    )
                                  : _buildLogoFallback(logoPath),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Success State/Loading State
                AnimatedOpacity(
                  opacity: _isSuccess ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Center(
                    child: Text(
                      'Success!', 
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                
                // Fade out fields on success
                AnimatedOpacity(
                  opacity: _isSuccess ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      Text(
                        'Welcome Back!',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rent the tools you need nearby.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          // Allow special admin username or valid email
                          if (value.trim() == 'aliadmin.1') return null;
                          if (!value.contains('@')) return 'Please enter a valid email';
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading || _isSuccess ? null : _login,
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // Sign Up Link (only show if not success)
                if (!_isSuccess)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoFallback(String logoPath) {
    return UniversalImage(
      key: const ValueKey('adawaty_logo'),
      imageUrl: logoPath,
      fit: BoxFit.cover,
      errorBuilder: (context) => Container(
        color: AppTheme.primaryColor.withOpacity(0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center_rounded, size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              'Adawaty',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
