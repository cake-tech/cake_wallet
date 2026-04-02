import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:flutter/material.dart';

class ChartsAssetGridHeader extends StatelessWidget {
  const ChartsAssetGridHeader({super.key, required this.onAddButtonPressed, required this.onSortButtonPressed});

  final VoidCallback onAddButtonPressed;
  final VoidCallback onSortButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
      Text(S.of(context).followed_assets, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      Row(spacing:8,children: [
        ModernButton.svg(size: 36, iconSize: 16,svgPath: "assets/new-ui/add.svg",onPressed: onAddButtonPressed,),
        ModernButton.svg(size: 36, iconSize: 16,svgPath: "assets/new-ui/sort.svg",onPressed: onSortButtonPressed,)

      ],)
    ],);
  }
}
