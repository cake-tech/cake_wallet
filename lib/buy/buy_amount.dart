import 'package:flutter/foundation.dart';

class BuyAmount {
  BuyAmount({
    @required this.sourceAmount,
    @required this.destAmount,
    this.minAmount = 0});

  final double sourceAmount;
  final double destAmount;
  final int minAmount;
}