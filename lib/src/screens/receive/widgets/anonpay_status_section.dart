import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';

class AnonInvoiceStatusSection extends StatelessWidget {
  const AnonInvoiceStatusSection({
    super.key,
    required this.invoiceInfo,
  });

  final AnonpayInvoiceInfo invoiceInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.current.status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryTextTheme.headline1!.decorationColor!,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).accentTextTheme.headline3!.color!,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SyncIndicatorIcon(
                      boolMode: false,
                      value: invoiceInfo.status ?? '',
                      size: 6,
                    ),
                    SizedBox(width: 5),
                    Text(
                      invoiceInfo.status ?? '',
                      style: textSmallSemiBold(
                        color: Theme.of(context).primaryTextTheme.headline6!.color,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          SizedBox(height: 27),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryTextTheme.headline1!.decorationColor!,
                ),
              ),
              Text(
                invoiceInfo.invoiceId ?? '',
                style: textSmallSemiBold(
                  color: Theme.of(context).primaryTextTheme.headline6!.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
