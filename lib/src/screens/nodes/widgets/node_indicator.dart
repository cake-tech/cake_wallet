import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class NodeIndicator extends StatelessWidget {
  NodeIndicator({this.isLive = false});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12.0,
      height: 12.0,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: isLive ? Palette.green : Palette.red),
    );
  }
}
