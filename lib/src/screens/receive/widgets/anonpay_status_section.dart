import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:cake_wallet/themes/extensions/address_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
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
        color: Theme.of(context).colorScheme.background,
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
                  color: Theme.of(context).extension<ExchangePageTheme>()!.receiveAmountColor,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).extension<AddressTheme>()!.actionButtonColor,
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
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
                  color: Theme.of(context).extension<ExchangePageTheme>()!.receiveAmountColor,
                ),
              ),
              Text(
                invoiceInfo.invoiceId ?? '',
                style: textSmallSemiBold(
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
