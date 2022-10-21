import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/info_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/receipt_row.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/view_model/cake_phone/add_balance_view_model.dart';

class AddBalancePage extends BasePage {
  AddBalancePage({required this.addBalanceViewModel})
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
        keyboardBarColor: Theme.of(context).accentTextTheme.bodyText1?.backgroundColor,
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
                    Theme.of(context).primaryTextTheme.subtitle1!.color!,
                    Theme.of(context).primaryTextTheme.subtitle1!.decorationColor!,
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
                        borderColor: Theme.of(context).primaryTextTheme.bodyText1?.decorationColor,
                        borderWidth: 0.5,
                        textStyle: TextStyle(fontSize: 36, fontWeight: FontWeight.w500, color: Colors.white),
                        placeholderTextStyle: TextStyle(
                          color: Theme.of(context).primaryTextTheme.headline5?.decorationColor,
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
                    color: Theme.of(context).primaryTextTheme.headline6?.color,
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
                              color: Theme.of(context).accentTextTheme.caption?.backgroundColor,
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
                                  color: Theme.of(context).primaryTextTheme.headline6?.color,
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
          bottomSection: Observer(builder: (_) {
            return LoadingPrimaryButton(
              onPressed: () {
                showPopUp<void>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertWithTwoActions(
                          alertTitle: S.of(context).confirm_sending,
                          alertTitleColor: Theme.of(context).primaryTextTheme.headline6!.decorationColor!,
                          alertContent: S.of(context).confirm_delete_template,
                          contentWidget: Material(
                            color: Colors.transparent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ReceiptRow(
                                    title: S.of(context).amount,
                                    value: cryptoAmount(addBalanceViewModel.buyAmountViewModel.doubleAmount)),
                                ReceiptRow(
                                    title: S.of(context).send_fee,
                                    value: cryptoAmount(getIt
                                        .get<AppStore>()
                                        .wallet
                                        !.calculateEstimatedFee(
                                          getIt.get<AppStore>().settingsStore.priority[getIt.get<AppStore>().wallet!.type]!,
                                          addBalanceViewModel.buyAmountViewModel.doubleAmount.floor(),
                                        )
                                        .toDouble())),
                                const SizedBox(height: 45),
                                Text(
                                  S.of(context).recipient_address,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryTextTheme.headline6?.color,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  //TODO: remove static address if it will be generated everytime
                                  "4B6c5ApfayzRN8jYxXyprv9me1vttSjF21WAz4HQ8JvS13RgRbgfQg7PPgvm2QMA8N1ed7izqPFsnCKGWWwFoGyjTFstzXm",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).accentTextTheme.subtitle1?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          isDividerExists: true,
                          rightButtonText: S.of(context).ok,
                          leftButtonText: S.of(context).cancel,
                          rightActionButtonColor: Theme.of(context).accentTextTheme.bodyText1!.color!,
                          leftActionButtonColor: Theme.of(context).primaryTextTheme.bodyText1!.backgroundColor!,
                          actionRightButton: () {
                            Navigator.of(dialogContext).pop();
                            showPaymentConfirmationPopup(context);
                          },
                          actionLeftButton: () => Navigator.of(dialogContext).pop());
                    });
              },
              text: S.of(context).buy,
              color: Theme.of(context).accentTextTheme.bodyText1?.color,
              textColor: Colors.white,
              isLoading: false,
              isDisabled: addBalanceViewModel.buyAmountViewModel.amount.isEmpty,
            );
          }),
        ),
      ),
    );
  }

  // TODO: Make it reusable after finding the models related and use it here and in phone_number_product_page.dart
  Widget cryptoAmount(double totalPrice) {
    return FutureBuilder<BuyAmount>(
      future: MoonPayBuyProvider(wallet: getIt.get<AppStore>().wallet!)
          .calculateAmount(totalPrice.toString(), FiatCurrency.usd.title),
      builder: (context, AsyncSnapshot<BuyAmount> snapshot) {
        double sourceAmount;
        double destAmount;

        if (snapshot.hasData && snapshot.data != null) {
          sourceAmount = snapshot.data!.sourceAmount;
          destAmount = snapshot.data!.destAmount;
        } else {
          sourceAmount = 0.0;
          destAmount = 0.0;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${sourceAmount} ${getIt.get<AppStore>().wallet!.currency.toString()}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryTextTheme.headline6?.color,
              ),
            ),
            Text(
              "${destAmount} ${FiatCurrency.usd.title}",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).accentTextTheme.subtitle1?.color,
              ),
            ),
          ],
        );
      },
    );
  }

  // TODO: Make it reusable after finding the models related and use it here and in phone_number_product_page.dart
  void showPaymentConfirmationPopup(BuildContext context) {
    showPopUp<void>(
        context: context,
        builder: (dialogContext) {
          return InfoAlertDialog(
            alertTitle: S.of(context).awaiting_payment_confirmation,
            alertTitleColor: Theme.of(context).primaryTextTheme.headline6?.decorationColor,
            alertContentPadding: EdgeInsets.zero,
            alertContent: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        S.of(context).transaction_sent_popup_info,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryTextTheme.headline6?.color,
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
                              color: Theme.of(context).accentTextTheme.subtitle1?.color,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 16),
                            child: Text(
                              // TODO: Replace with the transaction id
                              "dsyf5ind7akwryewkmf5nf4eakdrm4infd4i8rm4fd8nrmsein",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryTextTheme.headline6?.color,
                              ),
                            ),
                          ),
                          Text(
                            "${S.of(context).view_in_block_explorer}:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).accentTextTheme.subtitle1?.color,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              // TODO: get it from transaction details view model
                              S.of(context).view_transaction_on,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryTextTheme.headline6?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
