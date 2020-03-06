import 'package:flutter/material.dart';

class ImageWidget extends StatelessWidget {
  ImageWidget({
    @required this.image,
    @required this.aspectRatioImage,
    this.isLargeScreen = false});

  final Image image;
  final double aspectRatioImage;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    return isLargeScreen
    ? Flexible(
      child: Container(
        child: AspectRatio(
          aspectRatio: aspectRatioImage,
          child: FittedBox(
            fit: BoxFit.contain,
            child: image,
          ),
        ),
      ),
    )
    : image;
  }
}