import 'package:flutter/material.dart';

class StandardExpandableList<T> extends StatelessWidget {
  StandardExpandableList({
    required this.title,
    required this.expandableItems,
    this.decoration,
  });

  final String title;
  final List<T> expandableItems;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration ??
          BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Theme.of(context).colorScheme.onSurface,
          collapsedIconColor: Theme.of(context).colorScheme.onSurface,
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.left,
          ),
          children: expandableItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.toString(),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
