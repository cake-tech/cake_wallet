import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


 class SeedShowPageViewModel {
  SeedShowPageViewModel({required this.seed});

  final String seed;

  void copySeed(BuildContext context) {
    Clipboard.setData(ClipboardData(text: seed));
    showBar<void>(context, S.current.copied_to_clipboard);
  }
}