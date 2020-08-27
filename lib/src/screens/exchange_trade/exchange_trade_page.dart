import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_item.dart';
import 'package:cake_wallet/src/screens/exchange_trade/information_page.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/exchange_trade/exchange_trade_store.dart';
import 'package:cake_wallet/src/stores/send/send_store.dart';
import 'package:cake_wallet/src/stores/send/sending_state.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/widgets/timer_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';

void showInformation(ExchangeTradeViewModel exchangeTradeViewModel, BuildContext context) {
  final fetchingLabel = S.current.fetching;
  final trade = exchangeTradeViewModel.trade;
  final walletName = exchangeTradeViewModel.wallet.name;

  final information = exchangeTradeViewModel.isSendable
      ? S.current.exchange_result_confirm(
      trade.amount ?? fetchingLabel,
      trade.from.toString(),
      walletName)
      : S.current.exchange_result_description(
      trade.amount ?? fetchingLabel, trade.from.toString());

  showDialog<void>(
    context: context,
    builder: (_) => InformationPage(information: information)
  );
}

class ExchangeTradePage extends BasePage {
  ExchangeTradePage({@required this.exchangeTradeViewModel});

  final ExchangeTradeViewModel exchangeTradeViewModel;

  @override
  String get title => S.current.exchange;

  @override
  Widget trailing(BuildContext context) {
    final questionImage = Image.asset('assets/images/question_mark.png',
        color: Theme.of(context).primaryTextTheme.title.color);

    return SizedBox(
      height: 20.0,
      width: 20.0,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: FlatButton(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            padding: EdgeInsets.all(0),
            onPressed: () => showInformation(exchangeTradeViewModel, context),
            child: questionImage),
      ),
    );
  }

  @override
  Widget body(BuildContext context) => ExchangeTradeForm(exchangeTradeViewModel);
}

class ExchangeTradeForm extends StatefulWidget {
  ExchangeTradeForm(this.exchangeTradeViewModel);

  final ExchangeTradeViewModel exchangeTradeViewModel;

  @override
  ExchangeTradeState createState() => ExchangeTradeState();
}

class ExchangeTradeState extends State<ExchangeTradeForm> {
  final fetchingLabel = S.current.fetching;
  String get title => S.current.exchange;

  bool _effectsInstalled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    showInformation(widget.exchangeTradeViewModel, context);
  }

  @override
  Widget build(BuildContext context) {
    final copyImage = Image.asset('assets/images/copy_content.png',
        height: 16, width: 16,
        color: Theme.of(context).primaryTextTheme.overline.color);

    //_setEffects(context);

    return Container(
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(top: 10, bottom: 16),
        content: Observer(builder: (_) {
          final trade = widget.exchangeTradeViewModel.trade;

          return Column(
            children: <Widget>[
              trade.expiredAt != null
              ? Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                  Text(
                    S.of(context).offer_expires_in,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryTextTheme.overline.color),
                  ),
                  TimerWidget(trade.expiredAt,
                    color: Theme.of(context).primaryTextTheme.title.color)
                ])
              : Offstage(),
              Padding(
                padding: EdgeInsets.only(top: 32),
                child: Row(children: <Widget>[
                  Spacer(flex: 3),
                  Flexible(
                      flex: 4,
                      child: Center(
                          child: AspectRatio(
                              aspectRatio: 1.0,
                              child: QrImage(
                                data: trade.inputAddress ?? fetchingLabel,
                                backgroundColor: Colors.transparent,
                                foregroundColor: Theme.of(context)
                                    .accentTextTheme.subtitle.color,
                              )))),
                  Spacer(flex: 3)
                ]),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.exchangeTradeViewModel.items.length,
                  separatorBuilder: (context, index) => Container(
                    height: 1,
                    color: Theme.of(context).accentTextTheme.subtitle.backgroundColor,
                  ),
                  itemBuilder: (context, index) {
                    final item = widget.exchangeTradeViewModel.items[index];
                    String value;

                    final content = Observer(
                        builder: (_) {
                          switch (index) {
                            case 0:
                              value = '${widget.exchangeTradeViewModel.trade.id ?? fetchingLabel}';
                              break;
                            case 1:
                              value = '${widget.exchangeTradeViewModel.trade.amount ?? fetchingLabel}';
                              break;
                            case 2:
                              value = '${widget.exchangeTradeViewModel.trade.state ?? fetchingLabel}';
                              break;
                            case 3:
                              value = widget.exchangeTradeViewModel.trade.inputAddress ?? fetchingLabel;
                              break;
                          }

                          return StandartListRow(
                            title: item.title,
                            value: value,
                            valueFontSize: 14,
                            image: item.isCopied ? copyImage : null,
                          );
                        }
                    );

                    return item.isCopied
                        ? Builder(
                        builder: (context) =>
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: value));
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
                              child: content,
                            )
                    )
                        : content;
                  },
                ),
              ),
            ],
          );
        }),
        bottomSectionPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        bottomSection: PrimaryButton(
          onPressed: () {},
          text: S.of(context).confirm,
          color: Palette.blueCraiola,
          textColor: Colors.white
        )
        /*Observer(
            builder: (_) => tradeStore.trade.from == CryptoCurrency.xmr &&
                !(sendStore.state is TransactionCommitted)
                ? LoadingPrimaryButton(
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
                color: Colors.blue,
                textColor: Colors.white)
                : Offstage()),*/
      ),
    );
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    /*final sendStore = Provider.of<SendStore>(context);

    reaction((_) => sendStore.state, (SendingState state) {
      if (state is SendingFailed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).error,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop()
                );
              });
        });
      }

      if (state is TransactionCreatedSuccessfully) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithTwoActions(
                    alertTitle: S.of(context).confirm_sending,
                    alertContent: S.of(context).commit_transaction_amount_fee(
                        sendStore.pendingTransaction.amount,
                        sendStore.pendingTransaction.fee),
                    leftButtonText: S.of(context).ok,
                    rightButtonText: S.of(context).cancel,
                    actionLeftButton: () {
                      Navigator.of(context).pop();
                      sendStore.commitTransaction();
                    },
                    actionRightButton: () => Navigator.of(context).pop()
                );
              });
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).sending,
                    alertContent: S.of(context).transaction_sent,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop()
                );
              });
        });
      }
    });*/

    _effectsInstalled = true;
  }
}
