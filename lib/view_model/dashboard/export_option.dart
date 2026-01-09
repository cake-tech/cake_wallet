import 'package:flutter/material.dart';

class ExportOption {
  ExportOption({
    required this.title,
    required this.onTap,
    this.icon,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
}
