import 'package:flutter/material.dart';

enum ThemeType {light, bright, dark}

abstract class ThemeBase {
  ThemeBase({required this.raw});

  final int raw;
  String get title;
  ThemeData get themeData;
  ThemeType get type;

  @override
  String toString() {
    return title;
  }
}