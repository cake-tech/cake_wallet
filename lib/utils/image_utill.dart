import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ImageUtil {
  static Widget getImageFromPath({required String imagePath, double? height, double? width}) {
    final bool isNetworkImage = imagePath.startsWith('http') || imagePath.startsWith('https');
    final bool isSvg = imagePath.endsWith('.svg');
    final double _height = height ?? 35;
    final double _width = width ?? 35;

    if (isNetworkImage) {
      return isSvg
          ? SvgPicture.network(
              key: ValueKey(imagePath),
              imagePath,
              height: _height,
              width: _width,
              placeholderBuilder: (BuildContext context) => Container(
                height: _height,
                width: _width,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          : Image.network(
              key: ValueKey(imagePath),
              imagePath,
              height: _height,
              width: _width,
              loadingBuilder:
                  (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  height: _height,
                  width: _width,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return Container(
                  height: _height,
                  width: _width,
                );
              },
            );
    } else {
      return isSvg
          ? SvgPicture.asset(
              imagePath,
              height: _height,
              width: _width,
              placeholderBuilder: (_) => Icon(Icons.error),
              key: ValueKey(imagePath),
            )
          : Image.asset(
              imagePath,
              height: _height,
              width: _width,
              errorBuilder: (_, __, ___) => Icon(Icons.error),
              key: ValueKey(imagePath),
            );
    }
  }
}
