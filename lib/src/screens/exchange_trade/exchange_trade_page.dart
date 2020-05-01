import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/exchange_trade/exchange_trade_store.dart';
import 'package:cake_wallet/src/stores/send/send_store.dart';
import 'package:cake_wallet/src/stores/send/sending_state.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/exchange_trade/widgets/copy_button.dart';
import 'package:cake_wallet/src/screens/receive/qr_image.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/widgets/timer_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class ExchangeTradePage extends BasePage {
  @override
  String get title => S.current.exchange;

  @override
  Widget body(BuildContext context) => ExchangeTradeForm();
}

class ExchangeTradeForm extends StatefulWidget {
  @override
  ExchangeTradeState createState() => ExchangeTradeState();
}

class ExchangeTradeState extends State<ExchangeTradeForm> {
  final fetchingLabel = S.current.fetching;
  String get title => S.current.exchange;

  bool _effectsInstalled = false;

  @override
  Widget build(BuildContext context) {
    final tradeStore = Provider.of<ExchangeTradeStore>(context);
    final sendStore = Provider.of<SendStore>(context);
    final walletStore = Provider.of<WalletStore>(context);

    _setEffects(context);

    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.only(left: 20, right: 20, top: 20),
      content: Observer(builder: (_) {
        final trade = tradeStore.trade;
        final walletName = walletStore.name;

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            S.of(context).id,
                            style: TextStyle(
                                height: 2,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .button
                                    .color),
                          ),
                          Text(
                            '${trade.id ?? fetchingLabel}',
                            style: TextStyle(
                                fontSize: 14.0,
                                height: 2,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .subtitle
                                    .color),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            S.of(context).amount,
                            style: TextStyle(
                                height: 2,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .button
                                    .color),
                          ),
                          Text(
                            '${trade.amount ?? fetchingLabel}',
                            style: TextStyle(
                                fontSize: 14.0,
                                height: 2,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .subtitle
                                    .color),
                          )
                        ],
                      ),
                      trade.extraId != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  S.of(context).payment_id,
                                  style: TextStyle(
                                      height: 2,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.0,
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .button
                                          .color),
                                ),
                                Text(
                                  '${trade.extraId ?? fetchingLabel}',
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      height: 2,
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .subtitle
                                          .color),
                                )
                              ],
                            )
                          : Container(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            S.of(context).status,
                            style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .button
                                    .color,
                                height: 2),
                          ),
                          Text(
                            '${trade.state ?? fetchingLabel}',
                            style: TextStyle(
                                fontSize: 14.0,
                                height: 2,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .subtitle
                                    .color),
                          )
                        ],
                      ),
                      trade.expiredAt != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  S.of(context).offer_expires_in,
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .button
                                          .color),
                                ),
                                TimerWidget(trade.expiredAt,
                                    color: Theme.of(context)
                                        .primaryTextTheme
                                        .subtitle
                                        .color)
                              ],
                            )
                          : Container(),
                    ],
                  ),
                  SizedBox(width: 10),
                  Container(
                      padding: EdgeInsets.all(5),
                      color: Colors.white,
                      constraints: BoxConstraints(minWidth: 65, maxWidth: 105),
                      child: QrImage(
                          data: trade.inputAddress ?? fetchingLabel,
                          backgroundColor: Colors.white))
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Center(
              child: Text(
                S.of(context).trade_is_powered_by(trade.provider != null
                    ? trade.provider.title
                    : fetchingLabel),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryTextTheme.headline.color),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 20, bottom: 20),
              child: Center(
                child: Text(
                  trade.inputAddress ?? fetchingLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.0, color: Palette.lightViolet),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 50.0, right: 50.0),
              child: Row(
                children: <Widget>[
                  Flexible(
                      child: Container(
                    padding: EdgeInsets.only(right: 5.0),
                    child: CopyButton(
                        onPressed: () => Clipboard.setData(
                            ClipboardData(text: trade.inputAddress)),
                        text: S.of(context).copy_address,
                        color: Theme.of(context)
                            .accentTextTheme
                            .button
                            .backgroundColor,
                        borderColor: Theme.of(context)
                            .accentTextTheme
                            .button
                            .decorationColor),
                  )),
                  Flexible(
                      child: Container(
                    padding: EdgeInsets.only(left: 5.0),
                    child: CopyButton(
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: trade.id)),
                        text: S.of(context).copy_id,
                        color: Theme.of(context)
                            .accentTextTheme
                            .button
                            .backgroundColor,
                        borderColor: Theme.of(context)
                            .accentTextTheme
                            .button
                            .decorationColor),
                  ))
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                tradeStore.isSendable
                    ? S.of(context).exchange_result_confirm(
                        trade.amount ?? fetchingLabel,
                        trade.from.toString(),
                        walletName)
                    : S.of(context).exchange_result_description(
                        trade.amount ?? fetchingLabel, trade.from.toString()),
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 13.0,
                    color: Theme.of(context).primaryTextTheme.title.color),
              ),
            ),
            Text(
              S.of(context).exchange_result_write_down_ID,
              textAlign: TextAlign.left,
              style: TextStyle(
                  fontSize: 13.0,
                  color: Theme.of(context).accentTextTheme.title.color),
            )
          ],
        );
      }),
      bottomSection: Observer(
          builder: (_) => tradeStore.trade.from == CryptoCurrency.xmr &&
                  !(sendStore.state is TransactionCommitted)
              ? Container(
                  padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: LoadingPrimaryButton(
                      isDisabled: tradeStore.trade.inputAddress == null ||
                          tradeStore.trade.inputAddress.isEmpty,
                      isLoading: sendStore.state is CreatingTransaction ||
                          sendStore.state is TransactionCommitted,
                      onPressed: () => sendStore.createTransaction(
                          address: tradeStore.trade.inputAddress,
                          amount: tradeStore.trade.amount),
                      text: tradeStore.trade.provider ==
                              ExchangeProviderDescription.xmrto
                          ? S.of(context).confirm
                          : S.of(context).send_xmr,
                      color: Theme.of(context)
                          .primaryTextTheme
                          .button
                          .backgroundColor,
                      textColor: Theme.of(context).primaryTextTheme.button.color),
                )
              : Offstage()),
    );
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    final sendStore = Provider.of<SendStore>(context);

    reaction((_) => sendStore.state, (SendingState state) {
      if (state is SendingFailed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(S.of(context).error),
                  content: Text(state.error),
                  actions: <Widget>[
                    FlatButton(
                        child: Text(S.of(context).ok),
                        onPressed: () => Navigator.of(context).pop())
                  ],
                );
              });
        });
      }

      if (state is TransactionCreatedSuccessfully) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(S.of(context).confirm_sending),
                  content: Text(S.of(context).commit_transaction_amount_fee(
                      sendStore.pendingTransaction.amount,
                      sendStore.pendingTransaction.fee)),
                  actions: <Widget>[
                    FlatButton(
                        child: Text(S.of(context).ok),
                        onPressed: () {
                          Navigator.of(context).pop();
                          sendStore.commitTransaction();
                        }),
                    FlatButton(
                      child: Text(S.of(context).cancel),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                );
              });
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(S.of(context).sending),
                  content: Text(S.of(context).transaction_sent),
                  actions: <Widget>[
                    FlatButton(
                        child: Text(S.of(context).ok),
                        onPressed: () => Navigator.of(context).pop())
                  ],
                );
              });
        });
      }
    });

    _effectsInstalled = true;
  }
}
