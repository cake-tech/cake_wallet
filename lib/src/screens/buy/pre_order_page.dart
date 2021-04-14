import 'dart:ui';
import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/src/screens/buy/widgets/buy_list_item.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/view_model/buy/buy_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:mobx/mobx.dart';

class PreOrderPage extends BasePage {
  PreOrderPage({@required this.buyViewModel})
      : _amountFocus = FocusNode(),
        _amountController = TextEditingController() {

    _amountController.addListener(() {
      final amount = _amountController.text;

      if (amount != buyViewModel.buyAmountViewModel.amount) {
        buyViewModel.buyAmountViewModel.amount = amount;
      }

      if (buyViewModel.buyAmountViewModel.doubleAmount == 0.0) {
        buyViewModel.selectedProvider = null;
      }
    });

    reaction((_) => buyViewModel.buyAmountViewModel.amount, (String amount) {
      if (_amountController.text != amount) {
        _amountController.text = amount;
      }
    });
  }

  static const _amountPattern = '^([0-9]+([.\,][0-9]{0,2})?|[.\,][0-9]{1,2})\$';

  final BuyViewModel buyViewModel;
  final FocusNode _amountFocus;
  final TextEditingController _amountController;

  @override
  String get title => S.current.buy_bitcoin;

  @override
  Color get titleColor => Colors.white;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget trailing(context) => TrailButton(
      caption: S.of(context).clear,
      onPressed: () {
        buyViewModel.reset();
      });

  @override
  Widget body(BuildContext context) {
    return KeyboardActions(
      config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: Theme.of(context).accentTextTheme.body2
                .backgroundColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                focusNode: _amountFocus,
                toolbarButtons: [(_) => KeyboardDoneButton()],
              ),
            ]),
      child: Container(
          height: 0,
          color: Theme.of(context).backgroundColor,
          child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24)),
                    gradient: LinearGradient(colors: [
                      Theme.of(context).primaryTextTheme.subhead.color,
                      Theme.of(context)
                          .primaryTextTheme
                          .subhead
                          .decorationColor,
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Padding(
                      padding: EdgeInsets.only(top: 100, bottom: 65),
                      child: Center(
                        child: Container(
                          width: 165,
                          child: BaseTextFormField(
                            focusNode: _amountFocus,
                            controller: _amountController,
                            keyboardType:
                            TextInputType.numberWithOptions(
                                signed: false, decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .allow(RegExp(_amountPattern))
                            ],
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(top: 2),
                              child:
                              Text(buyViewModel.fiatCurrency.title + ': ',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )),
                            ),
                            hintText: '0.00',
                            borderColor: Theme.of(context)
                                .primaryTextTheme
                                .body2
                                .decorationColor,
                            borderWidth: 0.5,
                            textStyle: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                            placeholderTextStyle: TextStyle(
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .headline
                                    .decorationColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 36),
                          )
                        )
                      )
                  )
                ),
                Padding(
                  padding: EdgeInsets.only(top: 38, bottom: 18),
                  child: Text(
                    S.of(context).buy_with + ':',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).primaryTextTheme.title.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  )
                ),
                ...buyViewModel.items.map(
                  (item) => Observer(builder: (_) => FutureBuilder<BuyAmount>(
                      future: item.buyAmount,
                      builder: (context, AsyncSnapshot<BuyAmount> snapshot) {
                        double sourceAmount;
                        double destAmount;

                        if (snapshot.hasData) {
                          sourceAmount = snapshot.data.sourceAmount;
                          destAmount = snapshot.data.destAmount;
                        } else {
                          sourceAmount = 0.0;
                          destAmount = 0.0;
                        }

                        return Padding(
                            padding:
                                EdgeInsets.only(left: 15, top: 20, right: 15),
                            child: Observer(builder: (_) => BuyListItem(
                                selectedProvider: buyViewModel.selectedProvider,
                                provider: item.provider,
                                sourceAmount: sourceAmount,
                                sourceCurrency: buyViewModel.fiatCurrency,
                                destAmount: destAmount,
                                destCurrency: buyViewModel.cryptoCurrency,
                                onTap:
                                  buyViewModel.buyAmountViewModel
                                      .doubleAmount == 0.0 ? null : () {
                                  buyViewModel.selectedProvider = item.provider;
                                  sourceAmount > 0
                                      ? buyViewModel.isDisabled = false
                                      : buyViewModel.isDisabled = true;
                                }
                            ))
                        );
                      }
                  ),)
                )
              ],
            ),
            bottomSectionPadding:
              EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: Observer(builder: (_) {
                return LoadingPrimaryButton(
                    onPressed: buyViewModel.isRunning
                    ? null
                    :  () async {
                      buyViewModel.isRunning = true;
                      final url =
                        await buyViewModel.fetchUrl();
                      if (url.isNotEmpty) {
                        await Navigator.of(context)
                            .pushNamed(Routes.buyWebView, arguments: url);
                        buyViewModel.reset();
                      }
                      buyViewModel.isRunning = false;
                    },
                    text: buyViewModel.selectedProvider == null
                          ? S.of(context).buy
                          : S.of(context).buy_with +
                            ' ${buyViewModel.selectedProvider
                             .description.title}',
                    color: Theme.of(context).accentTextTheme.body2.color,
                    textColor: Colors.white,
                    isLoading: buyViewModel.isRunning,
                    isDisabled: (buyViewModel.selectedProvider == null) ||
                                buyViewModel.isDisabled
                );
              })
          )
      )
    );
  }
}