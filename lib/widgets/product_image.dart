import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Displays either a network or bundled product image with a warm loading
/// surface and a decor-focused fallback. The source path is never rewritten.
class ProductImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? iconSize;

  const ProductImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.iconSize = 32,
  });

  Widget _placeholder({bool loading = false}) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.lightCream, AppColors.softPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryPink,
                ),
              )
            : Icon(
                Icons.local_florist_outlined,
                size: iconSize,
                color: AppColors.primaryPink.withValues(alpha: 0.58),
              ),
      ),
    );
  }

  Widget _fadeIn(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) return child;
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = path.trim();
    if (source.isEmpty) return _placeholder();

    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: fit,
        frameBuilder: _fadeIn,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _placeholder(loading: true);
        },
      );
    }

    return Image.asset(
      source,
      fit: fit,
      frameBuilder: _fadeIn,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }
}
