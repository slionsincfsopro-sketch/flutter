import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class PaymentScreen extends StatefulWidget {
  final String requestId;
  final String itemId;
  final String renterId;

  const PaymentScreen({
    super.key, 
    required this.requestId, 
    required this.itemId,
    required this.renterId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  void _handlePayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);
      
      try {
        final firestore = context.read<FirestoreService>();
        
        // 1. Mark request as 'paid'
        await firestore.updateRequestStatus(widget.requestId, 'paid');
        
        // 2. Mark item as rented
        await firestore.rentItem(widget.itemId, widget.renterId);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Successful! Item Rented.')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment Failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Secure Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Method', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Your transaction is encrypted and secure.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 32),
              
              // Credit Card Decoration
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.contactless_outlined, color: Colors.white, size: 32),
                        Text('VISA', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      ],
                    ),
                    const Text('**** **** **** ****', style: TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('CARD HOLDER', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('EXPIRES', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Input Fields
              _buildInputLabel('Cardholder Name'),
              TextFormField(
                decoration: const InputDecoration(hintText: 'e.g. John Doe', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              
              _buildInputLabel('Card Number'),
              TextFormField(
                decoration: const InputDecoration(hintText: '0000 0000 0000 0000', prefixIcon: Icon(Icons.credit_card_rounded, size: 20)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.length < 16 ? 'Invalid Card Number' : null,
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         _buildInputLabel('Expiry Date'),
                         TextFormField(
                            decoration: const InputDecoration(hintText: 'MM/YY', prefixIcon: Icon(Icons.calendar_today_rounded, size: 18)),
                            keyboardType: TextInputType.datetime,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                       ],
                     ),
                   ),
                   const SizedBox(width: 20),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         _buildInputLabel('CVV'),
                         TextFormField(
                            decoration: const InputDecoration(hintText: '***', prefixIcon: Icon(Icons.lock_outline_rounded, size: 18)),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            validator: (v) => v!.length < 3 ? 'Invalid' : null,
                          ),
                       ],
                     ),
                   ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textPrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing 
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Pay & Confirm Rental', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text('Demo Mode: No actual funds will be charged', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
    );
  }
}
