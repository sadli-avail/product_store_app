import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/product.dart';
import '../../providers/product_provider.dart';

/// ProductFormScreen handles both Creating (Add) and Updating (Edit) a product.
/// If `product` parameter is passed, the form operates in Edit Mode.
/// Otherwise, it operates in Add Mode.
class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _brandController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _priceController = TextEditingController(text: p == null ? '' : p.price.toString());
    _imageUrlController = TextEditingController(text: p?.image ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProductProvider>();
    final original = widget.product;
    final imageUrl = _imageUrlController.text.trim();

    final productToSave = Product(
      id: original?.id ?? 0, // Generated in repository if new
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      brand: _brandController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      rating: original?.rating ?? 5.0,
      discount: original?.discount ?? 0.0,
      stock: original?.stock ?? 10,
      thumbnail: imageUrl,
      images: (original != null && original.images.isNotEmpty && imageUrl == original.image)
          ? original.images
          : (imageUrl.isNotEmpty ? [imageUrl] : []),
      isLocal: original?.isLocal ?? true,
      edited: _isEditing,
    );

    if (_isEditing) {
      provider.updateProduct(productToSave);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!')),
      );
    } else {
      provider.addProduct(productToSave);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New product added successfully!')),
      );
    }

    Navigator.pop(context);
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Product Title',
                  hint: 'e.g. Wireless Noise-Cancelling Headphones',
                  icon: Icons.title,
                  validator: (v) => _validateRequired(v, 'Title'),
                ),
                _buildTextField(
                  controller: _categoryController,
                  label: 'Category',
                  hint: 'e.g. electronics, groceries, beauty',
                  icon: Icons.category_outlined,
                  validator: (v) => _validateRequired(v, 'Category'),
                ),
                _buildTextField(
                  controller: _brandController,
                  label: 'Brand (Optional)',
                  hint: 'e.g. Sony, Apple, Samsung',
                  icon: Icons.branding_watermark_outlined,
                ),
                _buildTextField(
                  controller: _priceController,
                  label: 'Price (\$)',
                  hint: 'e.g. 99.99',
                  icon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Price is required';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed < 0) return 'Please enter a valid positive number';
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _imageUrlController,
                  label: 'Image URL (Optional)',
                  hint: 'https://example.com/product.jpg',
                  icon: Icons.image_outlined,
                  keyboardType: TextInputType.url,
                ),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Enter detailed specifications or description...',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (v) => _validateRequired(v, 'Description'),
                ),
                const SizedBox(height: 16),

                // Submit Button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveProduct,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isEditing ? 'Save Changes' : 'Create Product',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}
