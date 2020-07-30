import 'package:flutter/material.dart';

class AlertCloseButton extends StatelessWidget {
  AlertCloseButton({@required this.image});

  final Image image;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: 24,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle
            ),
            child: Center(
              child: image,
            ),
          ),
        )
    );
  }
}