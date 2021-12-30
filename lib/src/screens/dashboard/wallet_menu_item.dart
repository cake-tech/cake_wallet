import 'package:flutter/material.dart';

class WalletMenuItem {
  WalletMenuItem({
    @required this.title,
    @required this.image,
    @required this.handler});

  final String title;
  final Image image;
  final void Function() handler;
}