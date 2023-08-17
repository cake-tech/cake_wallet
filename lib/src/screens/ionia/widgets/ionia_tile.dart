import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

class IoniaTile extends StatelessWidget {
  const IoniaTile({
    Key? key,
    required this.title,
    required this.subTitle,
    this.onTap,
  }) : super(key: key);

  final VoidCallback? onTap;
  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textXSmall(
                color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subTitle,
              style: textMediumBold(
                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
              ),
            ),
          ],
        )
      ],
    ));
  }
}
