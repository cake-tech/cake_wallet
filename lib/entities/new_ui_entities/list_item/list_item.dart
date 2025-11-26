import 'package:flutter/material.dart';

abstract class ListItem {
  const ListItem({
    required this.keyValue,
    required this.label,
    this.isFirstInSection = false,
    this.isLastInSection = false,
  });

  final String keyValue;
  final String label;

  final bool isFirstInSection;
  final bool isLastInSection;

  BorderRadius get radius => BorderRadius.vertical(
    top: Radius.circular(isFirstInSection ? 16 : 0),
    bottom: Radius.circular(isLastInSection ? 16 : 0),
  );
}
