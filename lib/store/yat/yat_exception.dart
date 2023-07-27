import 'package:flutter/foundation.dart';

class YatException implements Exception {
  YatException({required this.text});

  final String text;

  @override
  String toString() => 'Yat exception: $text';
}