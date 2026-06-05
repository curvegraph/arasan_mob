import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';

class ImagePlaceholder extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final IconData icon;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ImagePlaceholder({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.icon = Icons.phone_android,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          height: height,
          width: width,
          fit: fit,
          placeholder: (_, __) => _buildPlaceholder(showLoading: true),
          errorWidget: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder({bool showLoading = false}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: (height ?? 100) * 0.25,
            color: AppColors.textHint,
          ),
          if (showLoading) ...[
            const SizedBox(height: 8),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
