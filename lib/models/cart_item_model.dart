class CartItemModel {
  final String userId;
  final String productId;
  final int quantity;

  CartItemModel({
    required this.userId,
    required this.productId,
    required this.quantity,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> data) {
    return CartItemModel(
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
    };
  }
}
