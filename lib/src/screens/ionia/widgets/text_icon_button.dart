import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';

class TextIconButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const TextIconButton({
    Key key,
    this.label,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return 
       InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: textMediumSemiBold(
                color: Theme.of(context).primaryTextTheme.title.color,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).primaryTextTheme.title.color,
            ),
          ],
        ),
    );
  }
}
