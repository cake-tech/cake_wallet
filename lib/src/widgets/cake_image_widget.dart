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
    this.semanticsLabel,
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

  /// Accessible name for this image.
  ///
  /// Leave `null` (the default) for decorative imagery — the image then
  /// contributes nothing at all to the semantics tree, so screen readers do not
  /// stop on an unnamed node. Pass a localized string only when the image is the
  /// sole carrier of information for the user.
  final String? semanticsLabel;

  bool get _isDecorative => semanticsLabel == null;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(context);
    }

    if (_isEmoji(imageUrl!)) {
      final size = height ?? width ?? 24;

      return SizedBox(
        height: height,
        width: width,
        child: Center(
          child: Text(
            imageUrl!,
            style: TextStyle(
              fontSize: size * 0.75,
              height: 1,
            ),
          ),
        ),
      );
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
            semanticsLabel: semanticsLabel,
            excludeFromSemantics: _isDecorative,
            fit: fit ?? BoxFit.contain, errorBuilder: (context, e, trace) {
          return SvgPicture.asset(
            imageUrl!,
            height: height,
            alignment: alignment ?? Alignment.center,
            allowDrawingOutsideViewBox: allowDrawingOutsideViewBox ?? false,
            width: width,
            errorBuilder: (_, __, ___) => SizedBox(height: height, width: width),
            colorFilter: effectiveColorFilter,
            semanticsLabel: semanticsLabel,
            excludeFromSemantics: _isDecorative,
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
          semanticLabel: semanticsLabel,
          excludeFromSemantics: _isDecorative,
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
              semanticsLabel: semanticsLabel,
              excludeFromSemantics: _isDecorative,
              placeholderBuilder: (_) => _buildLoadingWidget(),
              errorBuilder: (_, __, ___) => _buildErrorWidget(context),
            )
          : Image.network(
              imageUrl!,
              height: height,
              width: width,
              fit: fit ?? BoxFit.cover,
              color: color,
              filterQuality: filterQuality ?? FilterQuality.medium,
              semanticLabel: semanticsLabel,
              excludeFromSemantics: _isDecorative,
              loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
                if (progress == null) return child;
                return _buildLoadingWidget();
              },
              errorBuilder: (_, __, ___) => _buildErrorWidget(context),
            );
    }

    return imageWidget;
  }

  /// A caller-supplied [loadingWidget] owns its own semantics; the built-in
  /// spinner is purely visual and must not become an unnamed focus stop.
  Widget _buildLoadingWidget() =>
      loadingWidget ?? const ExcludeSemantics(child: Center(child: CircularProgressIndicator()));

  Widget _buildErrorWidget(BuildContext context) {
    final Widget placeholder = Container(
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

    // Several call sites render meaningful content (e.g. the asset's initials) as
    // their [errorWidget], so leave its semantics to the caller.
    if (errorWidget != null) {
      return placeholder;
    }

    return _isDecorative
        ? ExcludeSemantics(child: placeholder)
        : Semantics(
            container: true,
            image: true,
            label: semanticsLabel,
            child: ExcludeSemantics(child: placeholder),
          );
  }

  bool _isEmoji(String value) {
    if (value.startsWith("assets/") ||
        value.startsWith("http://") ||
        value.startsWith("https://")) {
      return false;
    }

    return value.runes.any(
          (rune) =>
      (rune >= 0x1F300 && rune <= 0x1FAFF) ||
          (rune >= 0x2600 && rune <= 0x27BF),
    );
  }
}
