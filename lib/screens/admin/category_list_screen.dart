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

  void _showCategoryDialog(BuildContext context, {CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    File? selectedImage;
    bool isUploading = false;
    String? currentImageUrl = category?.imageUrl;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(category == null ? 'Add Category' : 'Edit Category'),
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
                        : (currentImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    currentImageUrl,
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
                                )),
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

                          String? imageUrl = currentImageUrl;
                          if (selectedImage != null) {
                            imageUrl = await _storageService.uploadImage(
                              selectedImage!,
                            );
                          }

                          if (context.mounted) {
                            final db = Provider.of<DatabaseService>(
                              context,
                              listen: false,
                            );
                            if (category == null) {
                              await db.addCategory(
                                nameController.text.trim(),
                                imageUrl: imageUrl,
                              );
                            } else {
                              await db.updateCategory(
                                category.categoryId,
                                nameController.text.trim(),
                                imageUrl,
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        }
                      },
                child: Text(category == null ? 'Add' : 'Update'),
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
            onPressed: () => _showCategoryDialog(context),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () =>
                          _showCategoryDialog(context, category: category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await databaseService.deleteCategory(
                          category.categoryId,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
