import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// MessageView is a reusable widget for displaying Error and Empty states.
class MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const MessageView({
    super.key,
    required this.icon,
    this.title = '',
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),
            if (title.isNotEmpty) ...[
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh),
                label: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ProductImage displays an image with caching, placeholder, and error fallback.
class ProductImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final fallback = Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 40,
          color: colorScheme.onSurfaceVariant.withOpacity(0.4),
        ),
      ),
    );

    if (url.isEmpty || !url.startsWith('http')) {
      return fallback;
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, _) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, _, __) => fallback,
    );
  }
}
