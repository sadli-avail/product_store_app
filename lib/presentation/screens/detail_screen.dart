import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/product.dart';
import '../../providers/product_provider.dart';
import '../widgets/state_views.dart';
import 'product_form_screen.dart';

/// DetailScreen displays comprehensive product details, photo carousel,
/// pricing calculations, stock info, and allows editing or deleting the product.
class DetailScreen extends StatefulWidget {
  final int productId;

  const DetailScreen({super.key, required this.productId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _activeImageIndex = 0;

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to permanently delete "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<ProductProvider>().deleteProduct(product);
      Navigator.pop(context); // Return to home screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${product.title}" was deleted'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final product = provider.findById(widget.productId);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Handle case where product was deleted while viewing
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const MessageView(
          icon: Icons.search_off,
          title: 'Product Not Found',
          message: 'This product no longer exists or has been deleted.',
        ),
      );
    }

    final isFav = provider.isFavorite(product.id);
    final images = product.images.isNotEmpty
        ? product.images
        : (product.image.isNotEmpty ? [product.image] : <String>[]);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Favorite Action
          IconButton(
            tooltip: isFav ? 'Remove Favorite' : 'Add to Favorites',
            onPressed: () => provider.toggleFavorite(product.id),
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.redAccent : null,
            ),
          ),

          // Edit Action (CRUD: Update)
          IconButton(
            tooltip: 'Edit Product',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductFormScreen(product: product),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),

          // Delete Action (CRUD: Delete)
          IconButton(
            tooltip: 'Delete Product',
            onPressed: () => _confirmDelete(product),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Center(
        // Responsive maxWidth: keeps detail layout elegant on tablets & desktop
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Image Carousel with PageView & Indicator Dots
              Card(
                clipBehavior: Clip.antiAlias,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: SizedBox(
                  height: 320,
                  child: Stack(
                    children: [
                      images.isEmpty
                          ? const ProductImage(url: '')
                          : PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (i) => setState(() => _activeImageIndex = i),
                              itemBuilder: (_, i) => ProductImage(
                                url: images[i],
                                fit: BoxFit.contain,
                              ),
                            ),
                      // Indicator dots
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: i == _activeImageIndex ? 20 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: i == _activeImageIndex
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Product Title & Brand / Category
              Text(
                product.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.subtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // 3. Price & Discount Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.discount > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.discount.toStringAsFixed(1)}% OFF',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // 4. Feature Badges (Rating, Stock, Category, Product ID)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (product.rating > 0)
                    Chip(
                      avatar: const Icon(Icons.star, color: Colors.amber, size: 18),
                      label: Text('${product.rating} Rating'),
                    ),
                  Chip(
                    avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: Text(product.stock > 0 ? 'Stock: ${product.stock}' : 'In Stock'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.category_outlined, size: 18),
                    label: Text(product.category),
                  ),
                  Chip(
                    avatar: const Icon(Icons.tag, size: 16),
                    label: Text('ID: ${product.id}'),
                  ),
                  if (product.isLocal)
                    Chip(
                      backgroundColor: colorScheme.primaryContainer,
                      avatar: const Icon(Icons.smartphone, size: 16),
                      label: const Text('Created Locally'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Full Description
              Text(
                'Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description.isNotEmpty
                    ? product.description
                    : 'No detailed description provided for this product.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
