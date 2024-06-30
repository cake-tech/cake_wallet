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
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
      ),
    );
  }
}
