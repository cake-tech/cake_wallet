import 'dart:ui';
import 'package:flutter/cupertino.dart';

class WalletMenuItem {
  WalletMenuItem({
    @required this.title,
    @required this.firstGradientColor,
    @required this.secondGradientColor,
    @required this.image
  });

  final String title;
  final Color firstGradientColor;
  final Color secondGradientColor;
  final Image image;
}