import 'package:flutter/cupertino.dart';

class ExchangeTradeItem {
  ExchangeTradeItem({
    required this.title,
    required this.data,
    required this.isCopied,
  });

  String title;
  String data;
  bool isCopied;
}