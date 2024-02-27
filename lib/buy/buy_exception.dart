import 'package:flutter/foundation.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';

class BuyException implements Exception {
  BuyException({required this.title, required this.content});

  final String title;
  final String content;

  @override
  String toString() => '$title: $content';
}