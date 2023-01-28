import 'package:flutter/material.dart';

class WalletMenuItem {
  WalletMenuItem({
    required this.title,
    required this.image,
    required this.handler,
  });

  final String title;
  final String image;
  final void Function(BuildContext) handler;
}
