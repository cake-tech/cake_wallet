import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class NodeIndicator extends StatelessWidget {
  const NodeIndicator({this.isLive = false});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12.0,
      height: 12.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLive ? CustomThemeColors.syncGreen : Theme.of(context).colorScheme.errorContainer,
      ),
    );
  }
}
