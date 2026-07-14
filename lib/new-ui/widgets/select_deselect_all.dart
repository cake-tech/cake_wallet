import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class SelectDeselectAllBar extends StatelessWidget {
  const SelectDeselectAllBar({super.key, required this.title, required this.onSelected});

  final String title;
  final Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(
        title,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      Row(
        spacing: 20,
        children: [
          GestureDetector(
            onTap: () => onSelected(true),
            child: Text(
              S.of(context).select_all,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          GestureDetector(
            onTap: () => onSelected(false),
            child: Text(S.of(context).unselect_all,
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          )
        ],
      )
    ]);
  }
}
