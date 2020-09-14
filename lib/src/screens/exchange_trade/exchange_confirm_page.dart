import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';

class ExchangeConfirmPage extends BasePage {
  ExchangeConfirmPage({@required this.tradesStore}) : trade = tradesStore.trade;

  final TradesStore tradesStore;
  final Trade trade;

  @override
  String get title => S.current.copy_id;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: <Widget>[
          Expanded(
              child: Column(
                children: <Widget>[
                  Flexible(
                    child: Center(
                      child: Text(
                        S.of(context).exchange_result_write_down_trade_id,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryTextTheme.title.color),
                      ),
                    )
                  ),
                  Container(
                    height: 178,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      border: Border.all(
                        width: 1,
                        color: Theme.of(context).accentTextTheme.caption.color
                      ),
                      color: Theme.of(context).accentTextTheme.title.color
                    ),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  S.of(context).trade_id,
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).primaryTextTheme.overline.color
                                  ),
                                ),
                                Text(
                                  trade.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryTextTheme.title.color
                                  ),
                                ),
                              ],
                            ),
                          )
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Builder(
                            builder: (context) => PrimaryButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: trade.id));
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                      S.of(context).copied_to_clipboard,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(milliseconds: 1500),
                                  ));
                                },
                                text: S.of(context).copy_id,
                                color: Theme.of(context).accentTextTheme.caption.backgroundColor,
                                textColor: Theme.of(context).primaryTextTheme.title.color
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Flexible(
                    child: Offstage()
                  ),
                ],
              )
          ),
          PrimaryButton(
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(Routes.exchangeTrade),
              text: S.of(context).saved_the_trade_id,
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white)
        ],
      ),
    );
  }
}
