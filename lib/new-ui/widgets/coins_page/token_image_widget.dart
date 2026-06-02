import 'dart:async';
import 'dart:ui' as ui;

import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';

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
  static final Map<String, bool> _backdropCache = {};

  bool _needsBackdrop = false;

  @override
  void initState() {
    super.initState();
    _resolveBackdrop();
  }

  @override
  void didUpdateWidget(TokenImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolveBackdrop();
    }
  }

  Future<void> _resolveBackdrop() async {
    final url = widget.imageUrl;

    final cached = _backdropCache[url];
    if (cached != null) {
      if (mounted && _needsBackdrop != cached) {
        setState(() => _needsBackdrop = cached);
      }
      return;
    }

    final needs = await _isMostlyTransparent(url);
    _backdropCache[url] = needs;
    if (mounted) {
      setState(() => _needsBackdrop = needs);
    }
  }

  Future<bool> _isMostlyTransparent(String url) async {
    if (url.toLowerCase().endsWith('.svg')) return false;

    final ImageProvider provider;
    if (url.startsWith('assets/')) {
      provider = AssetImage(url);
    } else if (url.startsWith('http')) {
      provider = NetworkImage(url);
    } else {
      return false;
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
      if (byteData == null) return false;

      final totalPixels = image.width * image.height;
      var transparentPixels = 0;
      for (var i = 0; i < totalPixels; i++) {
        final alpha = byteData.getUint8(i * 4 + 3);
        if (alpha < 128) transparentPixels++;
      }

      return transparentPixels / totalPixels > 0.2;
    } catch (e) {
      printV('TokenImageWidget: failed to analyze $url: $e');
      return false;
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
        errorWidget: widget.errorWidget,
      ),
    );

    if (!_needsBackdrop) {
      return ClipOval(child: image);
    }

    return Container(
      width: widget.size,
      height: widget.size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: image,
    );
  }
}
