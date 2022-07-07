import 'dart:ui';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/view_model/cake_phone/add_balance_view_model.dart';

class AddBalancePage extends BasePage {
  AddBalancePage({@required this.addBalanceViewModel})
      : _amountFocus = FocusNode(),
        _amountController = TextEditingController() {
    _amountController.addListener(() {
      final amount = _amountController.text;

      if (amount != addBalanceViewModel.buyAmountViewModel.amount) {
        addBalanceViewModel.buyAmountViewModel.amount = amount;
      }
    });
  }

  static const _amountPattern = '^([0-9]+([.\,][0-9]{0,2})?|[.\,][0-9]{1,2})\$';

  final List<String> dummyProductsExamples = [
    "20 month of virtual phone service with 240 SMS",
    "500 additional SMS",
  ];

  final AddBalanceViewModel addBalanceViewModel;
  final FocusNode _amountFocus;
  final TextEditingController _amountController;

  @override
  String get title => S.current.add_balance;

  @override
  Color get titleColor => Colors.white;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget body(BuildContext context) {
    return KeyboardActions(
      config: KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
        keyboardBarColor: Theme.of(context).accentTextTheme.body2.backgroundColor,
        nextFocus: false,
        actions: [
          KeyboardActionsItem(
            focusNode: _amountFocus,
            toolbarButtons: [(_) => KeyboardDoneButton()],
          ),
        ],
      ),
      child: Container(
        height: 0,
        color: Theme.of(context).backgroundColor,
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(bottom: 24),
          content: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  gradient: LinearGradient(colors: [
                    Theme.of(context).primaryTextTheme.subhead.color,
                    Theme.of(context).primaryTextTheme.subhead.decorationColor,
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 100, bottom: 65),
                  child: Center(
                    child: Container(
                      width: 210,
                      child: BaseTextFormField(
                        focusNode: _amountFocus,
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(_amountPattern))],
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            FiatCurrency.usd.title + ': ',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        hintText: '0.00',
                        borderColor: Theme.of(context).primaryTextTheme.body2.decorationColor,
                        borderWidth: 0.5,
                        textStyle: TextStyle(fontSize: 36, fontWeight: FontWeight.w500, color: Colors.white),
                        placeholderTextStyle: TextStyle(
                          color: Theme.of(context).primaryTextTheme.headline.decorationColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 38, bottom: 18),
                child: Text(
                  "${S.of(context).cake_phone_products_example}:",
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.title.color,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: dummyProductsExamples
                      .map((e) => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).accentTextTheme.caption.backgroundColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: e,
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: " ${S.of(context).forwards}"),
                                ],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).primaryTextTheme.title.color,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          bottomSection: Observer(
            builder: (_) {
              return LoadingPrimaryButton(
                onPressed: () {

                },
                text: S.of(context).buy,
                color: Theme.of(context).accentTextTheme.body2.color,
                textColor: Colors.white,
                isLoading: false,
                isDisabled: addBalanceViewModel.buyAmountViewModel.amount.isEmpty,
              );
            }
          ),
        ),
      ),
    );
  }
}
