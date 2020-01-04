import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class NodeIndicator extends StatelessWidget {
  final color;

  NodeIndicator({this.color = Palette.red});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10.0,
      height: 10.0,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color),
    );
  }
}