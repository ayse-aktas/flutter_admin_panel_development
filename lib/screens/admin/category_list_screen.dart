import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_admin_panel_development/services/database_service.dart';
import 'package:flutter_admin_panel_development/models/category_model.dart';
import 'package:intl/intl.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final db = Provider.of<DatabaseService>(context, listen: false);
                await db.addCategory(nameController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: databaseService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                subtitle: Text(
                  'Created: ${DateFormat('dd MMM yyyy').format(category.createdAt)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await databaseService.deleteCategory(category.categoryId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
