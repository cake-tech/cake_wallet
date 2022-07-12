import 'package:cake_wallet/src/widgets/info_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfirmationAlertContent extends StatelessWidget {
  const ConfirmationAlertContent(this.transactionId, {Key key}) : super(key: key);

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return InfoAlertDialog(
      alertTitle: S.of(context).awaiting_payment_confirmation,
      alertTitleColor: Theme.of(context).primaryTextTheme.title.decorationColor,
      alertContentPadding: EdgeInsets.zero,
      alertContent: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                S.of(context).transaction_sent_popup_info,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryTextTheme.title.color,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Container(
                height: 1,
                color: Theme.of(context).dividerColor,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${S.of(context).transaction_details_transaction_id}:",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).accentTextTheme.subhead.color,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    child: Text(
                      transactionId,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryTextTheme.title.color,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      launch('https://monero.com/tx/${transactionId}');
                    },
                    child: StandartListRow(
                      title: '${S.of(context).view_in_block_explorer}:',
                      value: "${S.current.view_transaction_on + 'Monero.com'}",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
