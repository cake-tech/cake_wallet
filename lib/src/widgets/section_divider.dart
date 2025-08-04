import 'package:flutter/material.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider({required this.direction, this.margin});

  final Axis direction;
  final EdgeInsets? margin;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: direction == Axis.horizontal ? 1 : null,
      width: direction == Axis.vertical ? 1 : null,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
      margin: margin,
    );
  }
}

class HorizontalSectionDivider extends StatelessWidget {
  const HorizontalSectionDivider({this.margin});

  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return SectionDivider(direction: Axis.horizontal, margin: margin);
  }
}

class VerticalSectionDivider extends StatelessWidget {
  const VerticalSectionDivider();

  @override
  Widget build(BuildContext context) {
    return SectionDivider(direction: Axis.vertical);
  }
}
