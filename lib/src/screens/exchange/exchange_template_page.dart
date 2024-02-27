import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/exchange_card.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart';

class ExchangeTemplatePage extends BasePage {
  ExchangeTemplatePage(this.exchangeViewModel);

  final ExchangeViewModel exchangeViewModel;
  final depositKey = GlobalKey<ExchangeCardState>();
  final receiveKey = GlobalKey<ExchangeCardState>();
  final _formKey = GlobalKey<FormState>();
  final _depositAmountFocus = FocusNode();
  final _receiveAmountFocus = FocusNode();
  var _isReactionsSet = false;

  @override
  bool get gradientAll => true;

  @override
  String get title => S.current.exchange_new_template;

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

    return KeyboardActions(
        disableScroll: true,
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                  focusNode: _depositAmountFocus,
                  toolbarButtons: [(_) => KeyboardDoneButton()]),
              KeyboardActionsItem(
                  focusNode: _receiveAmountFocus,
                  toolbarButtons: [(_) => KeyboardDoneButton()])
            ]),
        child: Container(
        color: Theme.of(context).colorScheme.background,
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
                        Theme.of(context).extension<ExchangePageTheme>()!.firstGradientBottomPanelColor,
                        Theme.of(context).extension<ExchangePageTheme>()!.secondGradientBottomPanelColor,
                      ],
                      stops: [0.35, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
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
                                Theme.of(context).extension<ExchangePageTheme>()!.firstGradientTopPanelColor,
                                Theme.of(context).extension<ExchangePageTheme>()!.secondGradientTopPanelColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                        ),
                        padding: EdgeInsets.fromLTRB(24, 100, 24, 32),
                        child: Observer(
                          builder: (_) => ExchangeCard(
                            amountFocusNode: _depositAmountFocus,
                            key: depositKey,
                            title: S.of(context).you_will_send,
                            initialCurrency:
                            exchangeViewModel.depositCurrency,
                            initialWalletName: depositWalletName ?? '',
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
                            Theme.of(context).extension<ExchangePageTheme>()!.textFieldButtonColor,
                            borderColor: Theme.of(context).extension<ExchangePageTheme>()!.textFieldBorderBottomPanelColor,
                            currencyValueValidator: AmountValidator(
                                currency: exchangeViewModel.depositCurrency),
                            //addressTextFieldValidator: AddressValidator(
                            //    type: exchangeViewModel.depositCurrency),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 29, left: 24, right: 24),
                        child: Observer(
                            builder: (_) => ExchangeCard(
                              amountFocusNode: _receiveAmountFocus,
                              key: receiveKey,
                              title: S.of(context).you_will_get,
                              initialCurrency:
                              exchangeViewModel.receiveCurrency,
                              initialWalletName: receiveWalletName ?? '',
                              initialAddress:
                              exchangeViewModel.receiveCurrency ==
                                  exchangeViewModel.wallet.currency
                                  ? exchangeViewModel.wallet.walletAddresses.address
                                  : exchangeViewModel.receiveAddress,
                              initialIsAmountEditable: false,
                              isAmountEstimated: true,
                              isMoneroWallet: exchangeViewModel.isMoneroWallet,
                              currencies: exchangeViewModel.receiveCurrencies,
                              onCurrencySelected: (currency) =>
                                  exchangeViewModel.changeReceiveCurrency(
                                      currency: currency),
                              imageArrow: arrowBottomCakeGreen,
                              currencyButtonColor: Colors.transparent,
                              addressButtonsColor:
                              Theme.of(context).extension<ExchangePageTheme>()!.textFieldButtonColor,
                              borderColor: Theme.of(context).extension<ExchangePageTheme>()!.textFieldBorderBottomPanelColor,
                              currencyValueValidator: AmountValidator(
                                  currency: exchangeViewModel.receiveCurrency),
                              //addressTextFieldValidator: AddressValidator(
                              //    type: exchangeViewModel.receiveCurrency),
                            )),
                      )
                    ],
                  ),
                ),
              ),
              bottomSectionPadding:
              EdgeInsets.only(left: 24, right: 24, bottom: 24),
              bottomSection: Column(children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(bottom: 15),
                      child: Observer(
                        builder: (_) => Center(
                          child: Text(
                            S.of(context).amount_is_estimate,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .extension<ExchangePageTheme>()!
                                  .receiveAmountColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    PrimaryButton(
                    onPressed: () {
                      if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                        exchangeViewModel.addTemplate(
                            amount: exchangeViewModel.depositAmount,
                            depositCurrency:
                            exchangeViewModel.depositCurrency.name,
                            depositCurrencyTitle: exchangeViewModel
                                .depositCurrency.title + ' ${exchangeViewModel.depositCurrency.tag ?? ''}',
                            receiveCurrency:
                            exchangeViewModel.receiveCurrency.name,
                            receiveCurrencyTitle: exchangeViewModel
                                .receiveCurrency.title + ' ${exchangeViewModel.receiveCurrency.tag ?? ''}',
                            provider: exchangeViewModel.provider.toString(),
                            depositAddress: exchangeViewModel.depositAddress,
                            receiveAddress: exchangeViewModel.receiveAddress);
                        exchangeViewModel.updateTemplate();
                        Navigator.of(context).pop();
                      }
                    },
                    text: S.of(context).save,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white),
              ]),
            ))
      )
    );
  }

  void _setReactions(
      BuildContext context, ExchangeViewModel exchangeViewModel) {
    if (_isReactionsSet) {
      return;
    }

    final depositAddressController = depositKey.currentState!.addressController;
    final depositAmountController = depositKey.currentState!.amountController;
    final receiveAddressController = receiveKey.currentState!.addressController;
    final receiveAmountController = receiveKey.currentState!.amountController;
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
      if (depositKey.currentState!.amountController.text != amount) {
        depositKey.currentState!.amountController.text = amount;
      }
    });

    reaction((_) => exchangeViewModel.depositAddress, (String address) {
      if (depositKey.currentState!.addressController.text != address) {
        depositKey.currentState!.addressController.text = address;
      }
    });

    reaction((_) => exchangeViewModel.isDepositAddressEnabled,
            (bool isEnabled) {
          depositKey.currentState!.isAddressEditable(isEditable: isEnabled);
        });

    reaction((_) => exchangeViewModel.receiveAmount, (String amount) {
      if (receiveKey.currentState!.amountController.text != amount) {
        receiveKey.currentState!.amountController.text = amount;
      }
    });

    reaction((_) => exchangeViewModel.receiveAddress, (String address) {
      if (receiveKey.currentState!.addressController.text != address) {
        receiveKey.currentState!.addressController.text = address;
      }
    });

    reaction((_) => exchangeViewModel.provider, (ExchangeProvider? provider) {
      receiveKey.currentState!.isAmountEditable(isEditable: false);
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
        depositKey.currentState!.changeAddress(address: address);
      }

      if (exchangeViewModel.receiveCurrency == CryptoCurrency.xmr) {
        receiveKey.currentState!.changeAddress(address: address);
      }
    });

    _isReactionsSet = true;
  }

  void _onCurrencyChange(CryptoCurrency currency,
      ExchangeViewModel exchangeViewModel, GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == exchangeViewModel.wallet.currency;

    key.currentState!.changeSelectedCurrency(currency);
    key.currentState!.changeWalletName(
        isCurrentTypeWallet ? exchangeViewModel.wallet.name : '');

    key.currentState!.changeAddress(
        address: isCurrentTypeWallet
            ? exchangeViewModel.wallet.walletAddresses.address : '');

    key.currentState!.changeAmount(amount: '');
  }

  void _onWalletNameChange(ExchangeViewModel exchangeViewModel,
      CryptoCurrency currency, GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == exchangeViewModel.wallet.currency;

    if (isCurrentTypeWallet) {
      key.currentState!.changeWalletName(exchangeViewModel.wallet.name);
      key.currentState!.addressController.text =
          exchangeViewModel.wallet.walletAddresses.address;
    } else if (key.currentState!.addressController.text ==
        exchangeViewModel.wallet.walletAddresses.address) {
      key.currentState!.changeWalletName('');
      key.currentState!.addressController.text = '';
    }
  }
}
