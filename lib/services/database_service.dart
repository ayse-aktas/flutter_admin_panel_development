import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_admin_panel_development/models/category_model.dart';
import 'package:flutter_admin_panel_development/models/product_model.dart';
import 'package:flutter_admin_panel_development/models/order_model.dart';
import 'package:flutter_admin_panel_development/models/admin_stats_model.dart';
import 'package:flutter_admin_panel_development/models/user_model.dart';

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

  Future<void> addCategory(String name, {String? imageUrl}) async {
    WriteBatch batch = _firestore.batch();
    DocumentReference newCategoryRef = _firestore
        .collection('categories')
        .doc();
    DocumentReference statsRef = _firestore
        .collection('admin_stats')
        .doc('stats');

    batch.set(newCategoryRef, {
      'name': name,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Use set with merge to ensure stats doc exists and update atomically
    batch.set(statsRef, {
      'categories': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> updateCategory(
    String categoryId,
    String name,
    String? imageUrl,
  ) async {
    await _firestore.collection('categories').doc(categoryId).update({
      'name': name,
      'imageUrl': imageUrl,
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    WriteBatch batch = _firestore.batch();
    DocumentReference categoryRef = _firestore
        .collection('categories')
        .doc(categoryId);
    DocumentReference statsRef = _firestore
        .collection('admin_stats')
        .doc('stats');

    batch.delete(categoryRef);
    batch.set(statsRef, {
      'categories': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    await batch.commit();
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
    WriteBatch batch = _firestore.batch();
    DocumentReference newProductRef = _firestore
        .collection('products')
        .doc(); // Auto-id
    DocumentReference statsRef = _firestore
        .collection('admin_stats')
        .doc('stats');

    batch.set(newProductRef, {
      ...product.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(statsRef, {
      'products': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firestore
        .collection('products')
        .doc(product.productId)
        .update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    WriteBatch batch = _firestore.batch();
    DocumentReference productRef = _firestore
        .collection('products')
        .doc(productId);
    DocumentReference statsRef = _firestore
        .collection('admin_stats')
        .doc('stats');

    batch.delete(productRef);
    batch.set(statsRef, {
      'products': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    await batch.commit();
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

  Future<void> placeOrder(OrderModel order) async {
    WriteBatch batch = _firestore.batch();
    DocumentReference orderRef = _firestore
        .collection('orders')
        .doc(order.orderId);
    DocumentReference statsRef = _firestore
        .collection('admin_stats')
        .doc('stats');

    // 1. Create Order
    batch.set(orderRef, order.toMap());

    // 2. Update Admin Stats (Pending Order)
    batch.set(statsRef, {
      'pendingOrder': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // 3. Decrement Product Stock
    for (var item in order.products) {
      String productId = item['productId'];
      int quantity = item['quantity'];

      DocumentReference productRef = _firestore
          .collection('products')
          .doc(productId);
      batch.update(productRef, {'stock': FieldValue.increment(-quantity)});
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

  // --- Maintenance ---
  Future<void> recalculateStats() async {
    final productSnap = await _firestore.collection('products').count().get();
    final categorySnap = await _firestore
        .collection('categories')
        .count()
        .get();
    final userSnap = await _firestore
        .collection('users')
        .count()
        .get(); // Assuming users collection exists

    // For orders, we need to query based on status to get accurate counts
    // Using count() is cheaper than get() documents if we just need size
    final pendingSnap = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    final deliverySnap = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'delivery')
        .count()
        .get();
    final cancelSnap = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'cancelled')
        .count()
        .get();
    final completedSnap = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .count()
        .get();

    // Calculate earnings manually as we need to sum values
    final completedOrders = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .get();
    double totalEarning = 0;
    for (var doc in completedOrders.docs) {
      totalEarning += (doc.data()['totalPrice'] as num?)?.toDouble() ?? 0.0;
    }

    await _firestore.collection('admin_stats').doc('stats').set({
      'products': productSnap.count,
      'categories': categorySnap.count,
      'users': userSnap.count,
      'pendingOrder': pendingSnap.count,
      'deliveryOrder': deliverySnap.count,
      'cancelOrder': cancelSnap.count,
      'completedOrder': completedSnap.count,
      'earning': totalEarning,
    });
  }

  // --- Notifications ---
  Future<void> sendBroadcastNotification(String title, String body) async {
    await _firestore.collection('broadcast_notifications').add({
      'title': title,
      'body': body,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Users ---
  Stream<List<UserModel>> getUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> deleteUser(String uid) async {
    WriteBatch batch = _firestore.batch();
    DocumentReference userRef = _firestore.collection('users').doc(uid);
    DocumentReference statsRef = _firestore
        .collection('admin_stats')
        .doc('stats');

    batch.delete(userRef);
    batch.set(statsRef, {
      'users': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }
}
