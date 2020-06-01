import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';

class ExchangeConfirmPage extends BasePage {
  ExchangeConfirmPage({@required this.trade});

  final Trade trade;

  @override
  String get title => S.current.copy_id;

  @override
  Widget body(BuildContext context) {
    final copyImage = Image.asset('assets/images/copy_content.png',
        color: Theme.of(context).primaryTextTheme.title.color);

    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      S.of(context).exchange_result_write_down_trade_id,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryTextTheme.title.color),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Text(
                        S.of(context).trade_id,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryTextTheme.title.color),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Builder(
                        builder: (context) => GestureDetector(
                          onTap: () {
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
                          child: Container(
                            height: 60,
                            padding: EdgeInsets.only(left: 24, right: 24),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(30)),
                                color: Theme.of(context).accentTextTheme.title.backgroundColor
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    trade.id,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).primaryTextTheme.title.color
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: copyImage,
                                )
                              ],
                            ),
                          ),
                        )
                      ),
                    )
                  ],
                ),
              )),
          PrimaryButton(
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(Routes.exchangeTrade, arguments: trade),
              text: S.of(context).saved_the_trade_id,
              color: Colors.green,
              textColor: Colors.white)
        ],
      ),
    );
  }
}
