import 'dart:ui';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/exchange/xmrto/xmrto_exchange_provider.dart';
// import 'package:cake_wallet/exchange/exchange_trade_state.dart';
// import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/exchange_card.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart';

class ExchangeTemplatePage extends BasePage {
  ExchangeTemplatePage(this.exchangeViewModel);

  final ExchangeViewModel exchangeViewModel;
  final depositKey = GlobalKey<ExchangeCardState>();
  final receiveKey = GlobalKey<ExchangeCardState>();
  final _formKey = GlobalKey<FormState>();
  var _isReactionsSet = false;

  @override
  String get title => S.current.exchange_new_template;

  @override
  Color get titleColor => Colors.white;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget trailing(BuildContext context) =>
      PresentProviderPicker(exchangeViewModel: exchangeViewModel);

  @override
  Widget body(BuildContext context) {
    final arrowBottomPurple = Image.asset(
      'assets/images/arrow_bottom_purple_icon.png',
      color: Colors.white,
      height: 8,
    );
    final arrowBottomCakeGreen = Image.asset(
      'assets/images/arrow_bottom_cake_green.png',
      color: Colors.white,
      height: 8,
    );

    final depositWalletName =
    exchangeViewModel.depositCurrency == CryptoCurrency.xmr
        ? exchangeViewModel.wallet.name
        : null;
    final receiveWalletName =
    exchangeViewModel.receiveCurrency == CryptoCurrency.xmr
        ? exchangeViewModel.wallet.name
        : null;

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _setReactions(context, exchangeViewModel));

    return Container(
        color: Theme.of(context).backgroundColor,
        child: Form(
            key: _formKey,
            child: ScrollableWithBottomSection(
              contentPadding: EdgeInsets.only(bottom: 24),
              content: Container(
                padding: EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24)
                  ),
                  gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryTextTheme.body1.color,
                        Theme.of(context).primaryTextTheme.body1.decorationColor,
                      ],
                      stops: [0.35, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24)
                        ),
                        gradient: LinearGradient(
                            colors: [
                              Theme.of(context)
                                  .primaryTextTheme
                                  .subtitle
                                  .color,
                              Theme.of(context)
                                  .primaryTextTheme
                                  .subtitle
                                  .decorationColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                      ),
                      padding: EdgeInsets.fromLTRB(24, 90, 24, 32),
                      child: Observer(
                        builder: (_) => ExchangeCard(
                          key: depositKey,
                          title: S.of(context).you_will_send,
                          initialCurrency:
                          exchangeViewModel.depositCurrency,
                          initialWalletName: depositWalletName,
                          initialAddress: exchangeViewModel
                              .depositCurrency ==
                              exchangeViewModel.wallet.currency
                              ? exchangeViewModel.wallet.walletAddresses.address
                              : exchangeViewModel.depositAddress,
                          initialIsAmountEditable: true,
                          initialIsAddressEditable: exchangeViewModel
                              .isDepositAddressEnabled,
                          isAmountEstimated: false,
                          hasRefundAddress: true,
                          isMoneroWallet: exchangeViewModel.isMoneroWallet,
                          currencies: CryptoCurrency.all,
                          onCurrencySelected: (currency) =>
                              exchangeViewModel.changeDepositCurrency(
                                  currency: currency),
                          imageArrow: arrowBottomPurple,
                          currencyButtonColor: Colors.transparent,
                          addressButtonsColor:
                          Theme.of(context).focusColor,
                          borderColor: Theme.of(context)
                              .primaryTextTheme
                              .body2
                              .color,
                          currencyValueValidator: AmountValidator(
                              type: exchangeViewModel.wallet.type),
                          //addressTextFieldValidator: AddressValidator(
                          //    type: exchangeViewModel.depositCurrency),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 29, left: 24, right: 24),
                      child: Observer(
                          builder: (_) => ExchangeCard(
                            key: receiveKey,
                            title: S.of(context).you_will_get,
                            initialCurrency:
                            exchangeViewModel.receiveCurrency,
                            initialWalletName: receiveWalletName,
                            initialAddress:
                            exchangeViewModel.receiveCurrency ==
                                exchangeViewModel.wallet.currency
                                ? exchangeViewModel.wallet.walletAddresses.address
                                : exchangeViewModel.receiveAddress,
                            initialIsAmountEditable:
                            exchangeViewModel.provider is
                            XMRTOExchangeProvider ? true : false,
                            initialIsAddressEditable:
                            exchangeViewModel.isReceiveAddressEnabled,
                            isAmountEstimated: true,
                            isMoneroWallet: exchangeViewModel.isMoneroWallet,
                            currencies: exchangeViewModel.receiveCurrencies,
                            onCurrencySelected: (currency) =>
                                exchangeViewModel.changeReceiveCurrency(
                                    currency: currency),
                            imageArrow: arrowBottomCakeGreen,
                            currencyButtonColor: Colors.transparent,
                            addressButtonsColor:
                            Theme.of(context).focusColor,
                            borderColor: Theme.of(context)
                                .primaryTextTheme
                                .body2
                                .decorationColor,
                            currencyValueValidator: AmountValidator(
                                type: exchangeViewModel.wallet.type),
                            //addressTextFieldValidator: AddressValidator(
                            //    type: exchangeViewModel.receiveCurrency),
                          )),
                    )
                  ],
                ),
              ),
              bottomSectionPadding:
              EdgeInsets.only(left: 24, right: 24, bottom: 24),
              bottomSection: Column(children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Observer(builder: (_) {
                    final description =
                    exchangeViewModel.provider is XMRTOExchangeProvider
                        ? S.of(context).amount_is_guaranteed
                        : S.of(context).amount_is_estimate;
                    return Center(
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context)
                                .primaryTextTheme
                                .display4
                                .decorationColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
                      ),
                    );
                  }),
                ),
                PrimaryButton(
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        exchangeViewModel.addTemplate(
                            amount: exchangeViewModel.depositAmount,
                            depositCurrency:
                            exchangeViewModel.depositCurrency.toString(),
                            receiveCurrency:
                            exchangeViewModel.receiveCurrency.toString(),
                            provider: exchangeViewModel.provider.toString(),
                            depositAddress: exchangeViewModel.depositAddress,
                            receiveAddress: exchangeViewModel.receiveAddress);
                        exchangeViewModel.updateTemplate();
                        Navigator.of(context).pop();
                      }
                    },
                    text: S.of(context).save,
                    color: Colors.green,
                    textColor: Colors.white),
              ]),
            ))
    );
  }

  void _setReactions(
      BuildContext context, ExchangeViewModel exchangeViewModel) {
    if (_isReactionsSet) {
      return;
    }

    final depositAddressController = depositKey.currentState.addressController;
    final depositAmountController = depositKey.currentState.amountController;
    final receiveAddressController = receiveKey.currentState.addressController;
    final receiveAmountController = receiveKey.currentState.amountController;
    final limitsState = exchangeViewModel.limitsState;

    // FIXME: FIXME

    // final limitsState = exchangeViewModel.limitsState;
    //
    // if (limitsState is LimitsLoadedSuccessfully) {
    //   final min = limitsState.limits.min != null
    //       ? limitsState.limits.min.toString()
    //       : null;
    //   final max = limitsState.limits.max != null
    //       ? limitsState.limits.max.toString()
    //       : null;
    //   final key = depositKey;
    //   key.currentState.changeLimits(min: min, max: max);
    // }

    _onCurrencyChange(
        exchangeViewModel.receiveCurrency, exchangeViewModel, receiveKey);
    _onCurrencyChange(
        exchangeViewModel.depositCurrency, exchangeViewModel, depositKey);

    reaction(
            (_) => exchangeViewModel.wallet.name,
            (String _) => _onWalletNameChange(
            exchangeViewModel, exchangeViewModel.receiveCurrency, receiveKey));

    reaction(
            (_) => exchangeViewModel.wallet.name,
            (String _) => _onWalletNameChange(
            exchangeViewModel, exchangeViewModel.depositCurrency, depositKey));

    reaction(
            (_) => exchangeViewModel.receiveCurrency,
            (CryptoCurrency currency) =>
            _onCurrencyChange(currency, exchangeViewModel, receiveKey));

    reaction(
            (_) => exchangeViewModel.depositCurrency,
            (CryptoCurrency currency) =>
            _onCurrencyChange(currency, exchangeViewModel, depositKey));

    reaction((_) => exchangeViewModel.depositAmount, (String amount) {
      if (depositKey.currentState.amountController.text != amount) {
        depositKey.currentState.amountController.text = amount;
      }
    });

    reaction((_) => exchangeViewModel.depositAddress, (String address) {
      if (depositKey.currentState.addressController.text != address) {
        depositKey.currentState.addressController.text = address;
      }
    });

    reaction((_) => exchangeViewModel.isDepositAddressEnabled,
            (bool isEnabled) {
          depositKey.currentState.isAddressEditable(isEditable: isEnabled);
        });

    reaction((_) => exchangeViewModel.receiveAmount, (String amount) {
      if (receiveKey.currentState.amountController.text != amount) {
        receiveKey.currentState.amountController.text = amount;
      }
    });

    reaction((_) => exchangeViewModel.receiveAddress, (String address) {
      if (receiveKey.currentState.addressController.text != address) {
        receiveKey.currentState.addressController.text = address;
      }
    });

    reaction((_) => exchangeViewModel.isReceiveAddressEnabled,
            (bool isEnabled) {
          receiveKey.currentState.isAddressEditable(isEditable: isEnabled);
        });

    reaction((_) => exchangeViewModel.provider, (ExchangeProvider provider) {
      provider is XMRTOExchangeProvider
          ? receiveKey.currentState.isAmountEditable(isEditable: true)
          : receiveKey.currentState.isAmountEditable(isEditable: false);
    });

    /*reaction((_) => exchangeViewModel.limitsState, (LimitsState state) {
      String min;
      String max;

      if (state is LimitsLoadedSuccessfully) {
        min = state.limits.min != null ? state.limits.min.toString() : null;
        max = state.limits.max != null ? state.limits.max.toString() : null;
      }

      if (state is LimitsLoadedFailure) {
        min = '0';
        max = '0';
      }

      if (state is LimitsIsLoading) {
        min = '...';
        max = '...';
      }

      depositKey.currentState.changeLimits(min: min, max: max);
      receiveKey.currentState.changeLimits(min: null, max: null);
    });*/

    depositAddressController.addListener(
            () => exchangeViewModel.depositAddress = depositAddressController.text);

    depositAmountController.addListener(() {
      if (depositAmountController.text != exchangeViewModel.depositAmount) {
        exchangeViewModel.changeDepositAmount(
            amount: depositAmountController.text);
        exchangeViewModel.isReceiveAmountEntered = false;
      }
    });

    receiveAddressController.addListener(
            () => exchangeViewModel.receiveAddress = receiveAddressController.text);

    receiveAmountController.addListener(() {
      if (receiveAmountController.text != exchangeViewModel.receiveAmount) {
        exchangeViewModel.changeReceiveAmount(
            amount: receiveAmountController.text);
        exchangeViewModel.isReceiveAmountEntered = true;
      }
    });

    reaction((_) => exchangeViewModel.wallet.walletAddresses.address,
            (String address) {
      if (exchangeViewModel.depositCurrency == CryptoCurrency.xmr) {
        depositKey.currentState.changeAddress(address: address);
      }

      if (exchangeViewModel.receiveCurrency == CryptoCurrency.xmr) {
        receiveKey.currentState.changeAddress(address: address);
      }
    });

    _isReactionsSet = true;
  }

  void _onCurrencyChange(CryptoCurrency currency,
      ExchangeViewModel exchangeViewModel, GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == exchangeViewModel.wallet.currency;

    key.currentState.changeSelectedCurrency(currency);
    key.currentState.changeWalletName(
        isCurrentTypeWallet ? exchangeViewModel.wallet.name : null);

    key.currentState.changeAddress(
        address: isCurrentTypeWallet
            ? exchangeViewModel.wallet.walletAddresses.address : '');

    key.currentState.changeAmount(amount: '');
  }

  void _onWalletNameChange(ExchangeViewModel exchangeViewModel,
      CryptoCurrency currency, GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == exchangeViewModel.wallet.currency;

    if (isCurrentTypeWallet) {
      key.currentState.changeWalletName(exchangeViewModel.wallet.name);
      key.currentState.addressController.text =
          exchangeViewModel.wallet.walletAddresses.address;
    } else if (key.currentState.addressController.text ==
        exchangeViewModel.wallet.walletAddresses.address) {
      key.currentState.changeWalletName(null);
      key.currentState.addressController.text = null;
    }
  }
}