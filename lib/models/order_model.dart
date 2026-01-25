import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final List<Map<String, dynamic>> products; // Stores productId, quantity, price
  final double totalPrice;
  final String paymentMethod;
  final String status; // pending, cancelled, delivered, completed
  final DateTime createdAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.products,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String documentId) {
    return OrderModel(
      orderId: documentId,
      userId: data['userId'] ?? '',
      products: List<Map<String, dynamic>>.from(data['products'] ?? []),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'products': products,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
