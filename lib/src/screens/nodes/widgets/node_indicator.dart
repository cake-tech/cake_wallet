import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class NodeIndicator extends StatelessWidget {
  NodeIndicator({this.color = Palette.red});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8.0,
      height: 8.0,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
