import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_admin_panel_development/services/database_service.dart';
import 'package:flutter_admin_panel_development/models/admin_stats_model.dart';
import 'package:flutter_admin_panel_development/screens/admin/widgets/dashboard_card.dart';
import 'package:flutter_admin_panel_development/utils/constants.dart';
import 'package:flutter_admin_panel_development/screens/admin/product_list_screen.dart';
import 'package:flutter_admin_panel_development/screens/admin/category_list_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
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
                  onTap: () {}, // TODO: Navigate to Pending Orders
                ),
                DashboardCard(
                  title: 'Delivery Orders',
                  value: stats.deliveryOrder.toString(),
                  icon: Icons.local_shipping,
                  color: Colors.blue,
                  onTap: () {}, // TODO: Navigate to Delivery Orders
                ),
                DashboardCard(
                  title: 'Cancelled Orders',
                  value: stats.cancelOrder.toString(),
                  icon: Icons.cancel,
                  color: Colors.red,
                  onTap: () {}, // TODO: Navigate to Cancelled Orders
                ),
                DashboardCard(
                  title: 'Completed Orders',
                  value: stats.completedOrder.toString(),
                  icon: Icons.check_circle,
                  color: Colors.teal,
                  onTap: () {}, // TODO: Navigate to Completed Orders
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
                    );
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
                    );
                  },
                ),
                DashboardCard(
                  title: 'Users',
                  value: stats.users.toString(),
                  icon: Icons.people,
                  color: Colors.brown,
                  onTap: () {}, // TODO: Navigate to Users
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
