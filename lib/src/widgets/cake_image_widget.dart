import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CakeImageWidget extends StatelessWidget {
  const CakeImageWidget({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.fit,
    this.loadingWidget,
    this.errorWidget,
    this.color,
    this.borderRadius = 24.0,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Color? color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(context);
    }

    final isSvg = imageUrl!.toLowerCase().endsWith('.svg');
    final isAsset = imageUrl!.startsWith('assets/');

    Widget imageWidget;
    if (isAsset) {
      imageWidget = isSvg
          ? SvgPicture.asset(
              imageUrl!,
              height: height,
              width: width,
              color: color,
              fit: fit ?? BoxFit.contain,
            )
          : Image.asset(
              imageUrl!,
              height: height,
              width: width,
              fit: fit,
              color: color,
            );
    } else {
      imageWidget = isSvg
          ? SvgPicture.network(
              imageUrl!,
              height: height,
              width: width,
              color: color,
              fit: fit ?? BoxFit.contain,
              placeholderBuilder: (_) {
                return loadingWidget ?? const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, __, ___) => _buildErrorWidget(context),
            )
          : Image.network(
              imageUrl!,
              height: height,
              width: width,
              fit: fit ?? BoxFit.cover,
              color: color,
              loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
                if (progress == null) return child;
                return loadingWidget ?? const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, __, ___) => _buildErrorWidget(context),
            );
    }

    return imageWidget;
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: errorWidget ??
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
      ),
    );
  }
}
