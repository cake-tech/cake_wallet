import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/extensions/account_list_theme.dart';
import 'package:flutter/material.dart';

class ElectrumAddressTile extends StatelessWidget {
  ElectrumAddressTile({
    required this.address,
    required this.isChange,
    required this.onTap,
  });

  final String address;
  final bool isChange;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).extension<AccountListTheme>()!.tilesBackgroundColor;
    final textColor =
        Theme.of(context).extension<AccountListTheme>()!.tilesTextColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24),
        color: color,
        child: Column(
          children: [
            Expanded(child: SizedBox()),
            Expanded(
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                    color: Theme.of(context)
                        .extension<AccountListTheme>()!
                        .tilesAmountColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                child: Text(
                  isChange ? S.of(context).unspent_change : '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                    color: textColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
