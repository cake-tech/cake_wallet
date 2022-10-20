import 'package:flutter/foundation.dart';

class BuyAmount {
  BuyAmount({
    required this.sourceAmount,
    required this.destAmount,
    this.achSourceAmount,
    this.minAmount = 0});

  final double sourceAmount;
  final double destAmount;
  final double? achSourceAmount;
  final int minAmount;
}