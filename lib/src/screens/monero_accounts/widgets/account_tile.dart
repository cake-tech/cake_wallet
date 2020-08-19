import 'package:flutter/material.dart';

class AccountTile extends StatelessWidget {
  AccountTile({
    @required this.isCurrent,
    @required this.accountName,
    @required this.onTap
  });

  final bool isCurrent;
  final String accountName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? Theme.of(context).textTheme.subtitle.decorationColor
        : Theme.of(context).textTheme.display4.decorationColor;
    final textColor = isCurrent
        ? Theme.of(context).textTheme.subtitle.color
        : Theme.of(context).textTheme.display4.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 77,
        padding: EdgeInsets.only(left: 24, right: 24),
        alignment: Alignment.centerLeft,
        color: color,
        child: Text(
          accountName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}