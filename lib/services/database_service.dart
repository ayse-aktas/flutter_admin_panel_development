import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_admin_panel_development/models/category_model.dart';
import 'package:flutter_admin_panel_development/models/product_model.dart';
import 'package:flutter_admin_panel_development/models/order_model.dart';
import 'package:flutter_admin_panel_development/models/admin_stats_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Categories ---
  Stream<List<CategoryModel>> getCategories() {
    return _firestore
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> addCategory(String name) async {
    await _firestore.collection('categories').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  // --- Products ---
  Stream<List<ProductModel>> getProducts() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<ProductModel>> getProductsByCategory(String categoryId) {
    return _firestore
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> addProduct(ProductModel product) async {
    await _firestore.collection('products').add({
      ...product.toMap(),
      'createdAt':
          FieldValue.serverTimestamp(), // Override with server timestamp
    });
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firestore
        .collection('products')
        .doc(product.productId)
        .update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  // --- Orders ---
  Stream<List<OrderModel>> getOrders({String? status}) {
    Query query = _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
    OrderModel order,
  ) async {
    WriteBatch batch = _firestore.batch();
    DocumentReference orderRef = _firestore.collection('orders').doc(orderId);
    DocumentReference statsRef = _firestore
        .collection('admin_stats')
        .doc('stats');

    batch.update(orderRef, {'status': newStatus});

    // Update Admin Stats Logic
    // Decrease count of old status
    if (order.status == 'pending') {
      batch.update(statsRef, {'pendingOrder': FieldValue.increment(-1)});
    } else if (order.status == 'delivery') {
      // Assuming 'delivery' is the internal status string for delivery
      batch.update(statsRef, {'deliveryOrder': FieldValue.increment(-1)});
    }

    // Increase count of new status
    if (newStatus == 'cancelled') {
      batch.update(statsRef, {'cancelOrder': FieldValue.increment(1)});
    } else if (newStatus == 'delivery') {
      batch.update(statsRef, {'deliveryOrder': FieldValue.increment(1)});
    } else if (newStatus == 'completed') {
      batch.update(statsRef, {
        'completedOrder': FieldValue.increment(1),
        'earning': FieldValue.increment(order.totalPrice),
      });
    }

    await batch.commit();
  }

  // --- Admin Stats ---
  Stream<AdminStatsModel> getAdminStats() {
    return _firestore.collection('admin_stats').doc('stats').snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return AdminStatsModel.fromMap(doc.data()!);
      } else {
        return AdminStatsModel(
          earning: 0,
          pendingOrder: 0,
          deliveryOrder: 0,
          cancelOrder: 0,
          completedOrder: 0,
        );
      }
    });
  }
}
