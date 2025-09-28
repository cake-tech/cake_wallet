import 'dart:io';

import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageUtil {
  static Widget getImageFromPath({
    required String imagePath,
    double? height,
    double? width,
    Color? svgImageColor,
    BoxFit? fit,
    double? borderRadius,
  }) {
    bool isNetworkImage = imagePath.startsWith('http') || imagePath.startsWith('https');

    if (CakeTor.instance!.enabled && isNetworkImage) {
      imagePath = "assets/images/tor_logo.svg";
      isNetworkImage = false;
    }
    final isSvg = imagePath.endsWith('.svg');
    final bool ignoreSize = fit != null;
    final double? _height = ignoreSize ? null : (height ?? 35);
    final double? _width = ignoreSize ? null : (width ?? 35);

    Widget img;
    if (isNetworkImage) {
      img = isSvg
          ? SvgPicture.network(imagePath,
              key: ValueKey(imagePath),
              height: _height,
              width: _width,
              fit: fit ?? BoxFit.contain,
              placeholderBuilder: (_) => _placeholder(_height, _width),
              errorBuilder: (_, __, ___) => _errorPlaceholder(_height, _width))
          : Image.network(imagePath,
              key: ValueKey(imagePath),
              height: _height,
              width: _width,
              fit: fit,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _placeholder(_height, _width),
              errorBuilder: (_, __, ___) => _errorPlaceholder(_height, _width));
    } else {
      img = isSvg
          ? SvgPicture.asset(imagePath,
              key: ValueKey(imagePath),
              height: _height,
              width: _width,
              fit: fit ?? BoxFit.contain,
              colorFilter:
                  svgImageColor != null ? ColorFilter.mode(svgImageColor, BlendMode.srcIn) : null,
              placeholderBuilder: (_) => _placeholder(_height, _width),
              errorBuilder: (_, __, ___) => _errorPlaceholder(_height, _width))
          : Image.asset(
              imagePath,
              key: ValueKey(imagePath),
              height: _height,
              width: _width,
              fit: fit,
              errorBuilder: (_, __, ___) => _errorPlaceholder(_height, _width),
            );
    }

    if (borderRadius != null && borderRadius > 0) {
      img = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: img,
      );
    }
    return img;
  }

  static Future<String?> saveAvatarLocally(String imageUriOrPath) async {
    if (imageUriOrPath.isEmpty) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      String ext = p.extension(imageUriOrPath);
      if (ext.isEmpty) ext = '.png';

      final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext');

      if (imageUriOrPath.startsWith('http')) {
        final response = await ProxyWrapper()
            .get(
          clearnetUri: Uri.parse(imageUriOrPath),
        )
            .catchError((error) {
          throw Exception('HTTP request failed: $error');
        });

        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          return null;
        }
      } else {
        await File(imageUriOrPath).copy(file.path);
      }

      return file.existsSync() ? file.path : null;
    } catch (_) {
      return null;
    }
  }

  static Widget _placeholder(double? h, double? w) => (h != null || w != null)
      ? SizedBox(height: h, width: w, child: const Center(child: CircularProgressIndicator()))
      : const Center(child: CircularProgressIndicator());

  static Widget _errorPlaceholder(double? h, double? w) => (h != null || w != null)
      ? SizedBox(
          height: h,
          width: w,
          child: const Center(child: Icon(Icons.error_outline, color: Colors.grey)))
      : const Center(child: Icon(Icons.error_outline, color: Colors.grey));
}
