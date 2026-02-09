import 'package:flutter/foundation.dart';
import 'package:flutter_admin_panel_development/models/cart_item_model.dart';
import 'package:flutter_admin_panel_development/models/product_model.dart';

class CartService extends ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => _items;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount {
    return _items.length;
  }

  bool addToCart(ProductModel product, {int quantity = 1}) {
    // Check if product is already in cart
    final existingIndex = _items.indexWhere(
      (item) => item.product.productId == product.productId,
    );

    int currentQuantityInCart = 0;
    if (existingIndex >= 0) {
      currentQuantityInCart = _items[existingIndex].quantity;
    }

    if (currentQuantityInCart + quantity > product.stock) {
      return false; // Not enough stock
    }

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItemModel(product: product, quantity: quantity));
    }
    notifyListeners();
    return true;
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.productId == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _items.indexWhere(
      (item) => item.product.productId == productId,
    );
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
