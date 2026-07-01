import 'package:flutter/material.dart';

class CakePayCardImagePlaceholder extends StatelessWidget {
  const CakePayCardImagePlaceholder({this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: Container(
        child: Center(
          child: Text(
            text ?? 'Image not found!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
      ),
    );
  }
}
