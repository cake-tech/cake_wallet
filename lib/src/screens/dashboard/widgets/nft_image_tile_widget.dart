import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NFTImageWidget extends StatelessWidget {
  const NFTImageWidget({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    try {
      if (imageUrl == null) return Icon(Icons.error);

      if (imageUrl!.contains('.svg')) {
        return SvgPicture.network(imageUrl!);
      }

      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
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
      return Icon(Icons.error);
    }
  }
}
