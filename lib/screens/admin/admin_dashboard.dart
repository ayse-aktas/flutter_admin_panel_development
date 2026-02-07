import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_admin_panel_development/services/database_service.dart';
import 'package:flutter_admin_panel_development/models/admin_stats_model.dart';
import 'package:flutter_admin_panel_development/screens/admin/widgets/dashboard_card.dart';
import 'package:flutter_admin_panel_development/utils/constants.dart';
import 'package:flutter_admin_panel_development/screens/admin/product_list_screen.dart';
import 'package:flutter_admin_panel_development/screens/admin/category_list_screen.dart';
import 'package:flutter_admin_panel_development/services/auth_service.dart';
import 'package:flutter_admin_panel_development/models/user_model.dart';
import 'package:flutter_admin_panel_development/screens/admin/order_list_screen.dart';
import 'package:flutter_admin_panel_development/screens/admin/notification_screen.dart';
import 'package:flutter_admin_panel_development/screens/admin/user_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    // Dashboard açıldığında verilerin güncel olduğundan emin olmak için hesaplama yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStats();
    });
  }

  Future<void> _initStats() async {
    try {
      if (!mounted) return;
      final db = Provider.of<DatabaseService>(context, listen: false);
      // RecalculateStats mevcut "stats" dokümanını collections'dan sayarak günceller
      await db.recalculateStats();
    } catch (e) {
      debugPrint('Stats sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalculate Stats',
            onPressed: () async {
              final db = Provider.of<DatabaseService>(context, listen: false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recalculating stats...')),
              );
              await db.recalculateStats();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Stats updated!')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthService>().signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<AdminStatsModel>(
        stream: databaseService.getAdminStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stats =
              snapshot.data ??
              AdminStatsModel(
                earning: 0,
                pendingOrder: 0,
                deliveryOrder: 0,
                cancelOrder: 0,
                completedOrder: 0,
              );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Consumer<AuthService>(
                  builder: (context, authService, _) {
                    final user = authService.currentUser;
                    if (user == null) return const SizedBox.shrink();

                    return StreamBuilder<UserModel?>(
                      stream: authService.getUser(user.uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final userModel = snapshot.data!;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.red,
                                child: Text(
                                  userModel.name.isNotEmpty
                                      ? userModel.name[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userModel.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    userModel.email,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Send Notification to all users'),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      DashboardCard(
                        title: 'Total Earning',
                        value:
                            '${AppConstants.currencySymbol}${stats.earning.toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: Colors.green.shade700,
                        onTap: () {},
                      ),
                      DashboardCard(
                        title: 'Pending Orders',
                        value: stats.pendingOrder.toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrderListScreen(),
                            ),
                          ).then((_) => _initStats());
                        },
                      ),
                      DashboardCard(
                        title: 'Delivery Orders',
                        value: stats.deliveryOrder.toString(),
                        icon: Icons.local_shipping,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrderListScreen(),
                            ),
                          ).then((_) => _initStats());
                        },
                      ),
                      DashboardCard(
                        title: 'Cancelled Orders',
                        value: stats.cancelOrder.toString(),
                        icon: Icons.cancel,
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrderListScreen(),
                            ),
                          ).then((_) => _initStats());
                        },
                      ),
                      DashboardCard(
                        title: 'Completed Orders',
                        value: stats.completedOrder.toString(),
                        icon: Icons.check_circle,
                        color: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrderListScreen(),
                            ),
                          ).then((_) => _initStats());
                        },
                      ),
                      DashboardCard(
                        title: 'Products',
                        value: stats.products.toString(),
                        icon: Icons.inventory_2,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProductListScreen(),
                            ),
                          ).then((_) => _initStats());
                        },
                      ),
                      DashboardCard(
                        title: 'Categories',
                        value: stats.categories.toString(),
                        icon: Icons.category,
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoryListScreen(),
                            ),
                          ).then((_) => _initStats());
                        },
                      ),
                      DashboardCard(
                        title: 'Users',
                        value: stats.users.toString(),
                        icon: Icons.people,
                        color: Colors.brown,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserListScreen(),
                            ),
                          ).then((_) => _initStats());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
