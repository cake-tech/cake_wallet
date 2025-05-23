import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class WarningBox extends StatelessWidget {
  const WarningBox({required this.content, Key? key}) : super(key: key);

  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? CustomThemeColors.warningContainerColorDark
            : CustomThemeColors.warningContainerColorLight,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? CustomThemeColors.warningOutlineColorDark
              : CustomThemeColors.warningOutlineColorLight,
          width: 2.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
