import 'dart:async';
import 'dart:ui' as ui;

import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';

enum _IconShape {
  alreadyCircular,
  clipOnly,
  hollowNeedsBackdrop,
}

class TokenImageWidget extends StatefulWidget {
  const TokenImageWidget({
    super.key,
    required this.imageUrl,
    required this.size,
    this.errorWidget,
  });

  final String imageUrl;
  final double size;
  final Widget? errorWidget;

  @override
  State<TokenImageWidget> createState() => _TokenImageWidgetState();
}

class _TokenImageWidgetState extends State<TokenImageWidget> {
  static final Map<String, _IconShape> _shapeCache = {};

  _IconShape _shape = _IconShape.clipOnly;

  @override
  void initState() {
    super.initState();
    _resolveShape();
  }

  @override
  void didUpdateWidget(TokenImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolveShape();
    }
  }

  Future<void> _resolveShape() async {
    final url = widget.imageUrl;

    final cached = _shapeCache[url];
    if (cached != null) {
      if (mounted && _shape != cached) {
        setState(() => _shape = cached);
      }
      return;
    }

    final shape = await _analyzeShape(url);
    _shapeCache[url] = shape;
    if (mounted) {
      setState(() => _shape = shape);
    }
  }

  Future<_IconShape> _analyzeShape(String url) async {
    if (url.toLowerCase().endsWith('.svg')) return _IconShape.alreadyCircular;

    final ImageProvider provider;
    if (url.startsWith('assets/')) {
      provider = AssetImage(url);
    } else if (url.startsWith('http')) {
      provider = NetworkImage(url);
    } else {
      return _IconShape.clipOnly;
    }

    try {
      final completer = Completer<ui.Image>();
      final stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) completer.complete(info.image);
        },
        onError: (error, _) {
          if (!completer.isCompleted) completer.completeError(error);
        },
      );
      stream.addListener(listener);

      final image = await completer.future;
      stream.removeListener(listener);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return _IconShape.clipOnly;

      final totalPixels = image.width * image.height;
      var transparentPixels = 0;
      for (var i = 0; i < totalPixels; i++) {
        final alpha = byteData.getUint8(i * 4 + 3);
        if (alpha < 128) transparentPixels++;
      }

      final ratio = transparentPixels / totalPixels;

      if (ratio > 0.15 && ratio < 0.30) {
        return _IconShape.alreadyCircular;
      }

      if (ratio >= 0.30) {
        return _IconShape.hollowNeedsBackdrop;
      }

      return _IconShape.clipOnly;
    } catch (e) {
      printV('TokenImageWidget: failed to analyze $url: $e');
      return _IconShape.clipOnly;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      width: widget.size,
      height: widget.size,
      child: CakeImageWidget(
        imageUrl: widget.imageUrl,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorWidget: widget.errorWidget,
      ),
    );

    switch (_shape) {
      case _IconShape.alreadyCircular:
        return image;
      case _IconShape.clipOnly:
        return ClipOval(child: image);
      case _IconShape.hollowNeedsBackdrop:
        return Container(
          width: widget.size,
          height: widget.size,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: image,
        );
    }
  }
}
