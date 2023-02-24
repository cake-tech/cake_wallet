import 'package:flutter/material.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(context).dividerColor,
    );
  }
}