import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

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
    final color = isCurrent ? PaletteDark.lightOceanBlue : Colors.transparent;
    final textColor = isCurrent ? Colors.blue : Colors.white;

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