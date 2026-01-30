import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_admin_panel_development/services/database_service.dart';
import 'package:flutter_admin_panel_development/services/storage_service.dart';
import 'package:flutter_admin_panel_development/models/product_model.dart';
import 'package:flutter_admin_panel_development/models/category_model.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  String? _selectedCategoryId;
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString() ?? '',
    );
    _selectedCategoryId = widget.product?.categoryId;
    _uploadedImageUrl = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if category is selected
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    // Move provider access to sync part
    final storageService = Provider.of<StorageService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );

    setState(() => _isLoading = true);

    String imageUrl = _uploadedImageUrl ?? '';

    if (_selectedImage != null) {
      final url = await storageService.uploadImage(_selectedImage!);
      if (url != null) {
        imageUrl = url;
      } else {
        if (!mounted) {
          setState(() => _isLoading = false);
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image upload failed')));
        setState(() => _isLoading = false);
        return;
      }
    }

    // Prepare Model
    final productData = ProductModel(
      productId:
          widget.product?.productId ?? '', // Empty for new, populated for edit
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      stock: int.tryParse(_stockController.text) ?? 0,
      categoryId: _selectedCategoryId!,
      imageUrl: imageUrl,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.product == null) {
        await databaseService.addProduct(productData);
      } else {
        await databaseService.updateProduct(productData);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : (_uploadedImageUrl != null &&
                                  _uploadedImageUrl!.isNotEmpty)
                            ? Image.network(
                                _uploadedImageUrl!,
                                fit: BoxFit.cover,
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  Text('Tap to add image'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? 'Enter price' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(
                              labelText: 'Stock',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? 'Enter stock' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    StreamBuilder<List<CategoryModel>>(
                      stream: databaseService.getCategories(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final categories = snapshot.data!;
                        if (categories.isEmpty) {
                          return const Text(
                            'No categories found. Please add a category first.',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        // Ensure selected ID exists in the list
                        if (_selectedCategoryId != null &&
                            !categories.any(
                              (c) => c.categoryId == _selectedCategoryId,
                            )) {
                          _selectedCategoryId = null;
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category.categoryId,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Select category' : null,
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.product == null
                            ? 'Create Product'
                            : 'Update Product',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
