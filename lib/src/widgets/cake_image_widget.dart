import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CakeImageWidget extends StatelessWidget {
  CakeImageWidget({
    required this.imageUrl,
    Widget? displayOnError,
    this.height,
    this.width,
  }) : _displayOnError = displayOnError ?? Icon(Icons.error);

  final String? imageUrl;
  final double? height;
  final double? width;
  final Widget? _displayOnError;

  @override
  Widget build(BuildContext context) {
    try {
      if (imageUrl == null) return _displayOnError!;

      if (imageUrl!.contains('assets/images')) {
        return Image.asset(
          imageUrl!,
          height: height,
          width: width,
        );
      }

      if (imageUrl!.contains('.svg')) {
        return SvgPicture.network(
          imageUrl!,
          height: height,
          width: width,
        );
      }

      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        height: height,
        width: width,
        loadingBuilder: (BuildContext _, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            return child;
          } else {
            return CupertinoActivityIndicator(animating: true);
          }
        },
        errorBuilder: (_, __, ___) => Icon(Icons.error),
      );
    } catch (_) {
      return _displayOnError!;
    }
  }
}
