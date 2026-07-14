import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

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
    this.colorFilter,
    this.borderRadius = 24.0,
    this.alignment,
    this.allowDrawingOutsideViewBox,
    this.filterQuality,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Color? color;
  final ColorFilter? colorFilter;
  final AlignmentGeometry? alignment;
  final bool? allowDrawingOutsideViewBox;
  final double borderRadius;
  final FilterQuality? filterQuality;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(context);
    }

    final isSvg = imageUrl!.toLowerCase().endsWith('.svg');
    final isAsset = imageUrl!.startsWith('assets/');
    final effectiveColorFilter =
        colorFilter ?? (color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null);

    Widget imageWidget;
    if (isAsset) {
      if (isSvg) {
        imageWidget = SvgPicture(AssetBytesLoader("${imageUrl}.vec"),
            height: height,
            width: width,
            alignment: alignment ?? Alignment.center,
            allowDrawingOutsideViewBox: allowDrawingOutsideViewBox ?? false,
            colorFilter: effectiveColorFilter,
            fit: fit ?? BoxFit.contain, errorBuilder: (context, e, trace) {
          return SvgPicture.asset(
            imageUrl!,
            height: height,
            alignment: alignment ?? Alignment.center,
            allowDrawingOutsideViewBox: allowDrawingOutsideViewBox ?? false,
            width: width,
            errorBuilder: (_, __, ___) => SizedBox(height: height, width: width),
            colorFilter: effectiveColorFilter,
            fit: fit ?? BoxFit.contain,
          );
        });
      } else {
        imageWidget = Image.asset(
          imageUrl!,
          height: height,
          width: width,
          fit: fit,
          color: color,
          filterQuality: filterQuality ?? FilterQuality.medium,
          errorBuilder: (_, __, ___) => _buildErrorWidget(context),
        );
      }
    } else {
      imageWidget = isSvg
          ? SvgPicture.network(
              imageUrl!,
              height: height,
              width: width,
              colorFilter: effectiveColorFilter,
              alignment: alignment ?? Alignment.center,
              allowDrawingOutsideViewBox: allowDrawingOutsideViewBox ?? false,
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
              filterQuality: filterQuality ?? FilterQuality.medium,
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
