class AdminStatsModel {
  final double earning;
  final int pendingOrder;
  final int deliveryOrder;
  final int cancelOrder;
  final int completedOrder;
  final int products;
  final int users;
  final int categories;

  AdminStatsModel({
    required this.earning,
    required this.pendingOrder,
    required this.deliveryOrder,
    required this.cancelOrder,
    required this.completedOrder,
    this.products = 0,
    this.users = 0,
    this.categories = 0,
  });

  factory AdminStatsModel.fromMap(Map<String, dynamic> data) {
    return AdminStatsModel(
      earning: (data['earning'] as num?)?.toDouble() ?? 0.0,
      pendingOrder: (data['pendingOrder'] as num?)?.toInt() ?? 0,
      deliveryOrder: (data['deliveryOrder'] as num?)?.toInt() ?? 0,
      cancelOrder: (data['cancelOrder'] as num?)?.toInt() ?? 0,
      completedOrder: (data['completedOrder'] as num?)?.toInt() ?? 0,
      products: (data['products'] as num?)?.toInt() ?? 0,
      users: (data['users'] as num?)?.toInt() ?? 0,
      categories: (data['categories'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'earning': earning,
      'pendingOrder': pendingOrder,
      'deliveryOrder': deliveryOrder,
      'cancelOrder': cancelOrder,
      'completedOrder': completedOrder,
      'products': products,
      'users': users,
      'categories': categories,
    };
  }
}
