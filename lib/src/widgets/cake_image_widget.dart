import "dart:typed_data";

import "package:cake_wallet/src/widgets/remote_image_cache.dart";
import 'package:flutter/cupertino.dart';
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
    this.isRoundedSquare = false,
    this.outlineColor,
    this.fallbackName,
  }) : assert(
          (!isRoundedSquare && outlineColor == null && fallbackName == null) || width != null,
          "A rounded square, an outline or a fallback letter is sized from width",
        );

  static const networkIconCornerRatio = 7 / 24;

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

  final bool isRoundedSquare;
  final Color? outlineColor;
  final String? fallbackName;

  bool get _isDecorative => semanticsLabel == null;

  bool get _isFramed => isRoundedSquare || outlineColor != null;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      final placeholder = _buildErrorWidget(context);
      return _isFramed ? _ImageFrame(image: this, child: placeholder) : placeholder;
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
    } else if (RemoteImageCache.isRemote(imageUrl!)) {
      final remoteImage = RemoteImageCache.load(imageUrl!);
      imageWidget = FutureBuilder<Uint8List?>(
        future: remoteImage.bytesFuture,
        initialData: remoteImage.bytes,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null) {
            return snapshot.connectionState == ConnectionState.done
                ? _buildErrorWidget(context)
                : _buildLoadingWidget();
          }

          if (RemoteImageCache.isSvg(bytes)) {
            return SvgPicture.memory(
              bytes,
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
            );
          }

          return Image.memory(
            bytes,
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            filterQuality: filterQuality ?? FilterQuality.medium,
            semanticLabel: semanticsLabel,
            excludeFromSemantics: _isDecorative,
            errorBuilder: (_, __, ___) => _buildErrorWidget(context),
          );
        },
      );
    } else {
      imageWidget = _buildErrorWidget(context);
    }

    return _isFramed ? _ImageFrame(image: this, child: imageWidget) : imageWidget;
  }

  /// A caller-supplied [loadingWidget] owns its own semantics; the built-in
  /// spinner is purely visual and must not become an unnamed focus stop.
  Widget _buildLoadingWidget() {
    final fallbackName = this.fallbackName;
    if (loadingWidget == null && fallbackName != null) {
      return _FallbackLetter(name: fallbackName, size: width!);
    }

    return loadingWidget ??
        ExcludeSemantics(
          child: SizedBox(
            height: height,
            width: width,
            child: const Center(child: CupertinoActivityIndicator()),
          ),
        );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final fallbackName = this.fallbackName;
    if (fallbackName != null) {
      return _FallbackLetter(name: fallbackName, size: width!);
    }

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
}

class _ImageFrame extends StatelessWidget {
  const _ImageFrame({required this.image, required this.child});

  final CakeImageWidget image;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      image.isRoundedSquare ? image.width! * CakeImageWidget.networkIconCornerRatio : 0,
    );
    final outlineColor = image.outlineColor;

    return Container(
      width: image.width,
      height: image.height,
      foregroundDecoration: outlineColor == null
          ? null
          : BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: outlineColor, width: image.width! / 24),
            ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

class _FallbackLetter extends StatelessWidget {
  const _FallbackLetter({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmed = name.trim();

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        color: colors.primary,
        alignment: Alignment.center,
        child: Text(
          trimmed.isEmpty ? "" : trimmed.characters.first.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onPrimary,
                fontSize: size * 0.7,
                fontWeight: FontWeight.w400,
                height: 1,
              ),
        ),
      ),
    );
  }
}
