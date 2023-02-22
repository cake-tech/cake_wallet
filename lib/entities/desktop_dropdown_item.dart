import 'package:flutter/material.dart';

class DesktopDropdownItem {
  final Function() onSelected;
  final Widget child;
  final bool isSelected;

  DesktopDropdownItem({required this.onSelected, required this.child, this.isSelected = false});
}
