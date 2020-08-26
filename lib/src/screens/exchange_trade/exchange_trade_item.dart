import 'package:flutter/cupertino.dart';

class ExchangeTradeItem {
  ExchangeTradeItem({
    @required this.title,
    @required this.data,
    @required this.isCopied,
  });

  final String title;
  final String data;
  final bool isCopied;
}