import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../utils/image_utils.dart';
import '../../models/item_model.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  // ... (keep variables)
  final _formKey = GlobalKey<FormState>();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Cameras';
  final List<String> _categories = ['Cameras', 'Drones', 'Audio', 'Camping', 'Tools', 'Electronics', 'Others'];
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _postItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = context.read<AuthService>();
        final firestoreService = context.read<FirestoreService>();
        if (authService.currentUser == null) throw 'User not logged in';
        
        String imageUrl = '';
        if (_imageFile != null) {
           final base64String = await ImageUtils.fileToBase64(_imageFile!);
           if (base64String != null) {
             imageUrl = base64String;
           }
        }

        if (!mounted) return;

        final newItem = Item(
          id: '',
          title: _titleController.text,
          description: _descController.text,
          pricePerDay: double.tryParse(_priceController.text) ?? 0.0,
          rentalDuration: int.tryParse(_durationController.text) ?? 1,
          imageUrl: imageUrl,
          ownerId: authService.currentUser!.uid,
          category: _selectedCategory,
          createdAt: DateTime.now(),
        );

        await firestoreService.addItem(newItem);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item Listed Successfully!')),
          );
        }
      } on FirebaseException catch (e) {
        if (mounted) setState(() => _isLoading = false);
        
        if (e.code == 'permission-denied') {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Database Locked'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('The app cannot save items because the database security rules are blocking it.'),
                    SizedBox(height: 10),
                    Text('Go to Firebase Console -> Firestore Database -> Rules and change "allow read, write: if false" to "allow read, write: if true"'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.message}')),
            );
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted && _isLoading) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('List New Gear'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Equipment Details', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Share high-quality photos and clear details to attract more renters.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
              
              // Premium Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _imageFile == null ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                      width: 2,
                      style: _imageFile == null ? BorderStyle.solid : BorderStyle.none,
                    ),
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.05), shape: BoxShape.circle),
                                child: const Icon(Icons.add_a_photo_outlined, size: 32, color: AppTheme.primaryColor)),
                            const SizedBox(height: 16),
                            const Text('Add Primary Photo', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            const SizedBox(height: 4),
                            Text('JPEG or PNG supported', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: kIsWeb 
                                  ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                                  : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: IconButton.filled(
                                onPressed: () => setState(() => _imageFile = null),
                                icon: const Icon(Icons.close_rounded, size: 20),
                                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.9), foregroundColor: AppTheme.textPrimary),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Form Fields
              _buildFieldLabel('Item Title'),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'e.g., Professional Camera Rig'),
                validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),
              
              _buildFieldLabel('Daily Rental Price (EGP)'),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(hintText: '0.00', prefixIcon: Icon(Icons.payments_outlined, size: 20)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Please enter a price' : null,
              ),
              const SizedBox(height: 20),

              _buildFieldLabel('Category'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined, size: 20)),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 20),

              _buildFieldLabel('Rental Duration (Days)'),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(hintText: 'e.g., 7', prefixIcon: Icon(Icons.timer_outlined, size: 20)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Please enter duration' : null,
              ),
              const SizedBox(height: 20),
              
              _buildFieldLabel('Description'),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(hintText: 'Describe the condition and included accessories...', alignLabelWithHint: true),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _postItem,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.textPrimary),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Launch Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
    );
  }
}
