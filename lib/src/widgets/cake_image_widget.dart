import "dart:async";
import "dart:io";
import "package:cake_wallet/utils/network_image_cache.dart";
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
            excludeFromSemantics: true,
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
      imageWidget = _CachedNetworkImage(
        url: imageUrl!,
        isSvg: isSvg,
        fit: fit ?? (isSvg ? BoxFit.contain : BoxFit.cover),
        alignment: alignment ?? Alignment.center,
        allowDrawingOutsideViewBox: allowDrawingOutsideViewBox ?? false,
        filterQuality: filterQuality ?? FilterQuality.medium,
        excludeFromSemantics: _isDecorative,
        loadingWidget: _buildLoadingWidget(),
        errorWidget: _buildErrorWidget(context),
        height: height,
        width: width,
        color: color,
        colorFilter: effectiveColorFilter,
        semanticsLabel: semanticsLabel,
      );
    }

    return imageWidget;
  }

  /// A caller-supplied [loadingWidget] owns its own semantics; the built-in
  /// spinner is purely visual and must not become an unnamed focus stop.
  Widget _buildLoadingWidget() =>
      loadingWidget ?? ExcludeSemantics(child:SizedBox(
          height: height,
          width: width,
          child: Center(child: CupertinoActivityIndicator())));

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
}

class _CachedNetworkImage extends StatefulWidget {
  const _CachedNetworkImage({
    required this.url,
    required this.isSvg,
    required this.fit,
    required this.alignment,
    required this.allowDrawingOutsideViewBox,
    required this.filterQuality,
    required this.excludeFromSemantics,
    required this.loadingWidget,
    required this.errorWidget,
    this.height,
    this.width,
    this.color,
    this.colorFilter,
    this.semanticsLabel,
  });

  final String url;
  final bool isSvg;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool allowDrawingOutsideViewBox;
  final FilterQuality filterQuality;
  final bool excludeFromSemantics;
  final Widget loadingWidget;
  final Widget errorWidget;
  final double? height;
  final double? width;
  final Color? color;
  final ColorFilter? colorFilter;
  final String? semanticsLabel;

  @override
  State<_CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<_CachedNetworkImage> {
  File? _file;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_CachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final url = widget.url;
    _failed = false;
    _file = NetworkImageCache.instance.cachedFileSync(url);
    if (_file != null) {
      return;
    }

    try {
      final file = await NetworkImageCache.instance.getFile(url);
      if (mounted && widget.url == url) {
        setState(() => _file = file);
      }
    } catch (_) {
      if (mounted && widget.url == url) {
        setState(() => _failed = true);
      }
    }
  }

  Widget _buildDecodeErrorWidget() {
    unawaited(NetworkImageCache.instance.removeFromCache(widget.url));
    return widget.errorWidget;
  }

  @override
  Widget build(BuildContext context) => switch (_file) {
        null when _failed => widget.errorWidget,
        null => widget.loadingWidget,
        final file when widget.isSvg => SvgPicture.file(
            file,
            height: widget.height,
            width: widget.width,
            colorFilter: widget.colorFilter,
            alignment: widget.alignment,
            allowDrawingOutsideViewBox: widget.allowDrawingOutsideViewBox,
            fit: widget.fit,
            semanticsLabel: widget.semanticsLabel,
            excludeFromSemantics: widget.excludeFromSemantics,
            errorBuilder: (_, _, _) => _buildDecodeErrorWidget(),
          ),
        final file => Image.file(
            file,
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
            color: widget.color,
            filterQuality: widget.filterQuality,
            semanticLabel: widget.semanticsLabel,
            excludeFromSemantics: widget.excludeFromSemantics,
            errorBuilder: (_, _, _) => _buildDecodeErrorWidget(),
          ),
      };
}
