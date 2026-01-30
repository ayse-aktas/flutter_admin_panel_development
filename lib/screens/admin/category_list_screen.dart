import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_admin_panel_development/services/database_service.dart';
import 'package:flutter_admin_panel_development/models/category_model.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_admin_panel_development/services/storage_service.dart';
import 'package:intl/intl.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final StorageService _storageService = StorageService();

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    File? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        selectedImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey,
                              ),
                              Text(
                                'Tap to add image (Optional)',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                  ),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const Text('Uploading image...'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        if (nameController.text.isNotEmpty) {
                          setState(() => isUploading = true);

                          String? imageUrl;
                          if (selectedImage != null) {
                            imageUrl = await _storageService.uploadImage(
                              selectedImage!,
                            );
                          }

                          if (context.mounted) {
                            // Ensure the widget is still mounted before using context
                            final db = Provider.of<DatabaseService>(
                              context,
                              listen: false,
                            );
                            await db.addCategory(
                              nameController.text.trim(),
                              imageUrl: imageUrl,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        }
                      },
                child: const Text('Add'),
              ),
            ],
          );
        },
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
                leading: category.imageUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(category.imageUrl!),
                      )
                    : const CircleAvatar(child: Icon(Icons.category)),
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
