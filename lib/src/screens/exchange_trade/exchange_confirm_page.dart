import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';

class ExchangeConfirmPage extends BasePage {
  String get title => S.current.copy_id;

  final Trade trade;

  ExchangeConfirmPage({@required this.trade});

  @override
  Widget body(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
            child: Container(
                padding: EdgeInsets.only(left: 80.0, right: 80.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        S.of(context).exchange_result_write_down_trade_id,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18.0,
                            color: Theme.of(context)
                                .primaryTextTheme
                                .button
                                .color),
                      ),
                      SizedBox(
                        height: 70.0,
                      ),
                      Text(
                        S.of(context).trade_id(trade.id),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18.0,
                            color: Theme.of(context)
                                .primaryTextTheme
                                .button
                                .color),
                      ),
                      SizedBox(
                        height: 70.0,
                      ),
                      PrimaryButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: trade.id));
                            Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text(
                                S.of(context).copied_to_clipboard,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                            ));
                          },
                          text: S.of(context).copy_id,
                          color: Theme.of(context)
                              .accentTextTheme
                              .caption
                              .backgroundColor,
                          borderColor: Theme.of(context)
                              .accentTextTheme
                              .caption
                              .decorationColor)
                    ],
                  ),
                ))),
        Container(
          padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 40.0),
          child: PrimaryButton(
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(Routes.exchangeTrade, arguments: trade),
              text: S.of(context).saved_the_trade_id,
              color: Theme.of(context).primaryTextTheme.button.backgroundColor,
              borderColor:
                  Theme.of(context).primaryTextTheme.button.decorationColor),
        )
      ],
    );
  }
}
