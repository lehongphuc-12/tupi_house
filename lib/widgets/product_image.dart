import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget hiển thị ảnh sản phẩm, tự nhận diện:
/// - Nếu chuỗi bắt đầu bằng "http" → dùng Image.network (ảnh từ internet)
/// - Ngược lại → dùng Image.asset (ảnh local trong assets/images/products/...)
///
/// Nhờ vậy trường "image" trong db.json có thể là URL hoặc đường dẫn asset,
/// không cần sửa code khi đổi qua lại giữa 2 loại ảnh.
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

  Widget _errorPlaceholder() => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.local_florist,
            size: iconSize, color: AppColors.leafGreen),
      );

  @override
  Widget build(BuildContext context) {
    final isNetwork = path.startsWith('http');

    if (path.isEmpty) return _errorPlaceholder();

    if (isNetwork) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (c, e, s) => _errorPlaceholder(),
        loadingBuilder: (c, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (c, e, s) => _errorPlaceholder(),
    );
  }
}
