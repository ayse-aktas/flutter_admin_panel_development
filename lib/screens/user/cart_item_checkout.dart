import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_admin_panel_development/services/cart_service.dart';
import 'package:flutter_admin_panel_development/services/database_service.dart';
import 'package:flutter_admin_panel_development/services/auth_service.dart';
import 'package:flutter_admin_panel_development/models/order_model.dart';
import 'package:uuid/uuid.dart';

class CartItemCheckout extends StatefulWidget {
  const CartItemCheckout({super.key});

  @override
  State<CartItemCheckout> createState() => _CartItemCheckoutState();
}

class _CartItemCheckoutState extends State<CartItemCheckout> {
  String _paymentMethod = 'Cash on Delivery'; // Default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CartItemCheckout'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Payment Options
            _buildPaymentOption(
              title: 'Cash on Delivery',
              value: 'Cash on Delivery',
              icon: Icons.money,
            ),
            const SizedBox(height: 16),
            _buildPaymentOption(
              title: 'Pay Online',
              value: 'Pay Online',
              icon: Icons.payment,
            ),

            const Spacer(),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Continues',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 16),
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final cartService = context.read<CartService>();
    final databaseService = context.read<DatabaseService>();
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    // For testing/guest support
    final userId = user?.uid ?? 'guest_${const Uuid().v4().substring(0, 8)}';
    final userName = user?.displayName ?? 'Guest User';

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final orderId = const Uuid().v4();

      // Create Order Object
      final order = OrderModel(
        orderId: orderId,
        userId: userId,
        userName: userName,
        products: cartService.items
            .map(
              (item) => {
                'productId': item.product.productId,
                'name': item.product.name,
                'quantity': item.quantity,
                'price': item.product.price,
                'imageUrl': item.product.imageUrl,
              },
            )
            .toList(),
        totalPrice: cartService.totalAmount,
        paymentMethod: _paymentMethod,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Save to DB
      await databaseService.placeOrder(order);

      // Clear Cart
      cartService.clearCart();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show Success and Navigate Home or Back
        // The mock shows "Ordered Successfully" as a bottom sheet or similar.
        // We'll use a ModalBottomSheet or a Dialog, then pop back.

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordered Successfully'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a bit or let user click?
        // Showing a success dialog is cleaner.
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Center(
              child: Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            content: const Text(
              'Your order has been placed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Pop Checkout Screen
                    // Optionally pop Cart Screen too?
                    // Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        );

        if (mounted) {
          Navigator.pop(context); // Pop Checkout Screen
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    }
  }
}
