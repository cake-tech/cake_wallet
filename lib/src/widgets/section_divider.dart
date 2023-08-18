import 'package:flutter/material.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider({required this.direction});

  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: direction == Axis.horizontal ? 1 : null,
      width: direction == Axis.vertical ? 1 : null,
      color: Theme.of(context).dividerColor,
    );
  }
}

class HorizontalSectionDivider extends StatelessWidget {
  const HorizontalSectionDivider();

  @override
  Widget build(BuildContext context) {
    return SectionDivider(direction: Axis.horizontal);
  }
}

class VerticalSectionDivider extends StatelessWidget {
  const VerticalSectionDivider();

  @override
  Widget build(BuildContext context) {
    return SectionDivider(direction: Axis.vertical);
  }
}
