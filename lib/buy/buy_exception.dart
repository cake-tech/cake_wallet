import 'package:flutter/foundation.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';

class BuyException implements Exception {
  BuyException({required this.description, required this.text});

  final BuyProviderDescription description;
  final String text;

  @override
  String toString() => '${description.title}: $text';
}