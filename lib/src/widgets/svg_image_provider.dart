import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

// https://stackoverflow.com/a/79301729

class SvgImageProvider extends ImageProvider<SvgImageProvider> {
  final String assetName;
  final double scale;
  final Size? containerSize;

  const SvgImageProvider(this.assetName, {this.scale = 1.0, this.containerSize});

  @override
  Future<SvgImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<SvgImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(SvgImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadImage(key));
  }

  Future<ImageInfo> _loadImage(SvgImageProvider key) async {
    try {
      print('Loading SVG: ${key.assetName}');
      final bytes = await rootBundle.load(key.assetName);
      print('Bytes loaded: ${bytes.lengthInBytes}');

      final svg = await vg.loadPicture(SvgBytesLoader(bytes.buffer.asUint8List()), null);
      print('SVG loaded, original size: ${svg.size}');

      final size = svg.size;
      final deviceScale = key.scale;

      // Calculate dimensions to fit within container while maintaining aspect ratio
      double width, height;
      if (containerSize != null) {
        final aspectRatio = size.width / size.height;
        if (containerSize!.width / containerSize!.height > aspectRatio) {
          height = containerSize!.height;
          width = height * aspectRatio;
        } else {
          width = containerSize!.width;
          height = width / aspectRatio;
        }
      } else {
        width = size.width;
        height = size.height;
      }

      // Scale by device pixel ratio
      final scaledWidth = (width * deviceScale).round();
      final scaledHeight = (height * deviceScale).round();

      print('Rendering at: $scaledWidth x $scaledHeight (device scale: $deviceScale)');
      assert(
          scaledWidth > 0 && scaledHeight > 0, 'Invalid target size: $scaledWidth x $scaledHeight');

      final recorder = PictureRecorder();
      final canvas =
          Canvas(recorder, Rect.fromLTWH(0, 0, scaledWidth.toDouble(), scaledHeight.toDouble()));
      canvas.transform(
          Matrix4.diagonal3Values(scaledWidth / size.width, scaledHeight / size.height, 1.0)
              .storage);
      canvas.drawPicture(svg.picture);
      final image = await recorder.endRecording().toImage(scaledWidth, scaledHeight);
      print('Image rendered: ${image.width} x ${image.height}');
      return ImageInfo(image: image, scale: deviceScale);
    } catch (e, stackTrace) {
      print('Error loading SVG: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is SvgImageProvider &&
        other.assetName == assetName &&
        other.scale == scale &&
        other.containerSize == containerSize;
  }

  @override
  int get hashCode => Object.hash(assetName, scale, containerSize);
}
