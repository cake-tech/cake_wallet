import 'package:cake_wallet/src/screens/exchange_trade/widgets/exchange_trade_card_item_widget.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class ExchangeTradeExternalSendPage extends BasePage {
  ExchangeTradeExternalSendPage({required this.exchangeTradeViewModel});

  final ExchangeTradeViewModel exchangeTradeViewModel;
  @override
  String get title => S.current.swap;

  @override
  bool get gradientAll => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  final fetchingLabel = S.current.fetching;

  @override
  Widget body(BuildContext context) {
    final copyImage = Image.asset(
      'assets/images/copy_content.png',
      height: 16,
      width: 16,
      color: Theme.of(context).extension<SendPageTheme>()!.estimatedFeeColor,
    );
    return Container(
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(bottom: 24),
        content: Observer(
          builder: (_) {
            return Column(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).extension<SendPageTheme>()!.firstGradientColor,
                        Theme.of(context).extension<SendPageTheme>()!.secondGradientColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(24, 110, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Spacer(flex: 3),
                          Flexible(
                            flex: 6,
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 3,
                                      color: Theme.of(context)
                                          .extension<ExchangePageTheme>()!
                                          .qrCodeColor,
                                    ),
                                  ),
                                  child: QrImage(
                                    data:
                                        exchangeTradeViewModel.trade.inputAddress ?? fetchingLabel,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Spacer(flex: 3)
                        ],
                      ),
                      SizedBox(height: 24),
                      ...exchangeTradeViewModel.items
                          .where((item) => item.isExternalSendDetail)
                          .map(
                            (item) => TradeItemRowWidget(
                              currentTheme: currentTheme,
                              title: item.title,
                              value: item.data,
                              isCopied: true,
                              copyImage: copyImage,
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomSection: Observer(
          builder: (_) {
            final trade = exchangeTradeViewModel.trade;
            final sendingState = exchangeTradeViewModel.sendViewModel.state;

            return exchangeTradeViewModel.isSendable && !(sendingState is TransactionCommitted)
                ? LoadingPrimaryButton(
                    key: ValueKey('exchange_trade_external_send_page_continue_button_key'),
                    isDisabled: trade.inputAddress == null || trade.inputAddress!.isEmpty,
                    isLoading: sendingState is IsExecutingState,
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    text: S.current.continue_text,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                  )
                : Offstage();
          },
        ),
      ),
    );
  }
}
