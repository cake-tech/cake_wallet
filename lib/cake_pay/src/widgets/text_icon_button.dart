import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';

class TextIconButton extends StatelessWidget {
  const TextIconButton({
    Key? key,
    required this.label,
    this.onTap,
  }) : super(key: key);

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
          ),
        ],
      ),
    );
  }
}
