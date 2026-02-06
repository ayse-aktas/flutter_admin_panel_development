import 'package:flutter/material.dart';
import 'package:flutter_admin_panel_development/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_admin_panel_development/models/order_model.dart';
import 'package:flutter_admin_panel_development/services/auth_service.dart';
import 'package:flutter_admin_panel_development/services/database_service.dart';
import 'package:uuid/uuid.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart'), centerTitle: true),
      body: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartService.items.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartService.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: cartItem.product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      cartItem.product.imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image, size: 80),
                            ),
                            const SizedBox(width: 16),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${cartItem.product.price.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Controls
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    cartService.updateQuantity(
                                      cartItem.product.productId,
                                      cartItem.quantity - 1,
                                    );
                                  },
                                ),
                                Text(
                                  '${cartItem.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    cartService.updateQuantity(
                                      cartItem.product.productId,
                                      cartItem.quantity + 1,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Total and Checkout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${cartService.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final cartService = context.read<CartService>();
                            final databaseService = context
                                .read<DatabaseService>();
                            final authService = context.read<AuthService>();
                            final user = authService.currentUser;

                            // For testing, we allow guests.
                            // In real app we might force login.
                            final userId =
                                user?.uid ??
                                'guest_${const Uuid().v4().substring(0, 8)}';
                            final userName = user?.displayName ?? 'Guest User';

                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
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
                                paymentMethod: 'Credit Card', // Mock
                                status: 'pending',
                                createdAt: DateTime.now(),
                              );

                              // Save to DB
                              await databaseService.placeOrder(order);

                              // Clear Cart
                              cartService.clearCart();

                              if (context.mounted) {
                                Navigator.pop(context); // Close loading

                                // Show Success and go back
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Success!'),
                                    content: const Text(
                                      'Your order has been placed successfully.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // Close alert
                                          // Optionally navigate to Orders tab if we had one
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); // Close loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Order failed: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
