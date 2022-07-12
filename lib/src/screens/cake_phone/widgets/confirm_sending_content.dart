import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/cake_phone_entities/top_up.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/receipt_row.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/xmr_amount.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/cake_phone/phone_plan_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class ConfirmSendingContent extends StatelessWidget {
  const ConfirmSendingContent(this.totalPrice, {Key key}) : super(key: key);

  final double totalPrice;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TopUp>(
      future: getIt.get<PhonePlanViewModel>().getMoneroPaymentInfo(totalPrice * 1000),
      builder: (context, AsyncSnapshot<TopUp> snapshot) {
        double xmrAmount = 0.0;
        String address;

        if (snapshot.hasData) {
          xmrAmount = snapshot.data.amount;
          address = snapshot.data.address;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReceiptRow(
              title: S.of(context).amount,
              value: XMRAmount(xmrAmount: xmrAmount, fiatAmount: totalPrice),
            ),
            ReceiptRow(
              title: S.of(context).send_fee,
              // TODO: remove dummy xmrAmount after checking if there will be fees or not and if so from which API
              /// since the monero API is only returning the amount and address not the fees
              value: XMRAmount(
                  xmrAmount: 1500,
                  fiatAmount: getIt
                      .get<AppStore>()
                      .wallet
                      .calculateEstimatedFee(
                        getIt.get<AppStore>().settingsStore.priority[WalletType.monero],
                        totalPrice.floor(),
                      )
                      .toDouble()),
            ),
            const SizedBox(height: 45),
            if (address != null)
              Column(
                children: [
                  Text(
                    S.of(context).recipient_address,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryTextTheme.title.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).accentTextTheme.subhead.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
          ],
        );
      },
    );
  }
}
