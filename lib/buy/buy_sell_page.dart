import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';

import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/desktop_exchange_cards_section.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/mobile_exchange_cards_section.dart';
import 'package:cake_wallet/src/widgets/add_template_button.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/debounce.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/buy/buy_sell_view_model.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/src/screens/send/widgets/extract_address_from_parsed.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/template_tile.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/exchange_card.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';

class BuySellPage extends BasePage {
  BuySellPage(this.buySellViewModel);

  final BuySellViewModel buySellViewModel;
  final cryptoCurrencyKey = GlobalKey<ExchangeCardState>();
  final fiatCurrencyKey = GlobalKey<ExchangeCardState>();
  final _formKey = GlobalKey<FormState>();
  final _depositAmountFocus = FocusNode();
  final _depositAddressFocus = FocusNode();
  final _receiveAmountFocus = FocusNode();
  final _receiveAddressFocus = FocusNode();
  final _receiveAmountDebounce = Debounce(Duration(milliseconds: 500));
  Debounce _depositAmountDebounce = Debounce(Duration(milliseconds: 500));
  var _isReactionsSet = false;

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

  late final String? depositWalletName;
  late final String? receiveWalletName;

  @override
  String get title => S.current.buy + '/' + S.current.sell;

  @override
  bool get gradientBackground => true;

  @override
  bool get gradientAll => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Function(BuildContext)? get pushToNextWidget => (context) {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.focusedChild?.unfocus();
        }
      };

  @override
  Widget trailing(BuildContext context) => TrailButton(
      caption: S.of(context).clear,
      onPressed: () {
        _formKey.currentState?.reset();
      });

  @override
  Widget? leading(BuildContext context) {
    final _backButton = Icon(
      Icons.arrow_back_ios,
      color: titleColor(context),
      size: 16,
    );
    final _closeButton =
        currentTheme.type == ThemeType.dark ? closeButtonImageDarkTheme : closeButtonImage;

    bool isMobileView = responsiveLayoutUtil.shouldRenderMobileUI;

    return MergeSemantics(
      child: SizedBox(
        height: isMobileView ? 37 : 45,
        width: isMobileView ? 37 : 45,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: Semantics(
            label: !isMobileView ? S.of(context).close : S.of(context).seed_alert_back,
            child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateColor.resolveWith((states) => Colors.transparent),
              ),
              onPressed: () => onClose(context),
              child: !isMobileView ? _closeButton : _backButton,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _setReactions(context, buySellViewModel));

    return KeyboardActions(
        disableScroll: true,
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                  focusNode: _depositAmountFocus, toolbarButtons: [(_) => KeyboardDoneButton()]),
              KeyboardActionsItem(
                  focusNode: _receiveAmountFocus, toolbarButtons: [(_) => KeyboardDoneButton()])
            ]),
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: Form(
              key: _formKey,
              child: ScrollableWithBottomSection(
                contentPadding: EdgeInsets.only(bottom: 24),
                content: Observer(
                  builder: (_) => Column(
                    children: <Widget>[
                      _exchangeCardsSection(context),
                      Padding(
                          padding: EdgeInsets.only(top: 12, left: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              StandardCheckbox(
                                value: false,
                                caption: S.of(context).fixed_rate,
                                onChanged: (value) {},
                              ),
                            ],
                          )),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
                bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
                bottomSection: Column(children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Observer(builder: (_) {
                      final description = S.of(context).variable_pair_not_supported;
                      return Center(
                        child: Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .extension<ExchangePageTheme>()!
                                  .receiveAmountColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12),
                        ),
                      );
                    }),
                  ),
                  Observer(
                      builder: (_) => LoadingPrimaryButton(
                          text: S.of(context).exchange,
                          onPressed: () {},
                          color: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                          isDisabled: false,
                          isLoading: false)),
                ]),
              )),
        ));
  }

  void _setReactions(BuildContext context, BuySellViewModel buySellViewModel) {
    if (_isReactionsSet) {
      return;
    }

    // if (exchangeViewModel.isLowFee) {
    //   _showFeeAlert(context);
    // }
    //
    // final depositAddressController = depositKey.currentState!.addressController;
    // final depositAmountController = depositKey.currentState!.amountController;
    // final receiveAddressController = receiveKey.currentState!.addressController;
    // final receiveAmountController = receiveKey.currentState!.amountController;
    // final limitsState = exchangeViewModel.limitsState;
    //
    // if (limitsState is LimitsLoadedSuccessfully) {
    //   final min = limitsState.limits.min != null ? limitsState.limits.min.toString() : null;
    //   final max = limitsState.limits.max != null ? limitsState.limits.max.toString() : null;
    //   final key = exchangeViewModel.isFixedRateMode ? receiveKey : depositKey;
    //   key.currentState!.changeLimits(min: min, max: max);
    // }

    _onCryptoCurrencyChange(buySellViewModel.cryptoCurrency, buySellViewModel, cryptoCurrencyKey);
    _onFiatCurrencyChange(buySellViewModel.fiatCurrency, buySellViewModel, fiatCurrencyKey);

    // reaction(
    //     (_) => exchangeViewModel.wallet.name,
    //     (String _) =>
    //         _onWalletNameChange(exchangeViewModel, exchangeViewModel.receiveCurrency, receiveKey));
    //
    // reaction(
    //     (_) => exchangeViewModel.wallet.name,
    //     (String _) =>
    //         _onWalletNameChange(exchangeViewModel, exchangeViewModel.depositCurrency, depositKey));

    reaction(
        (_) => buySellViewModel.cryptoCurrency,
        (CryptoCurrency currency) =>
            _onCryptoCurrencyChange(currency, buySellViewModel, cryptoCurrencyKey));

    reaction(
        (_) => buySellViewModel.fiatCurrency,
        (FiatCurrency currency) =>
            _onFiatCurrencyChange(currency, buySellViewModel, fiatCurrencyKey));

    // reaction((_) => exchangeViewModel.depositAmount, (String amount) {
    //   if (depositKey.currentState!.amountController.text != amount && amount != S.of(context).all) {
    //     depositKey.currentState!.amountController.text = amount;
    //   }
    // });
    //
    // reaction((_) => exchangeViewModel.depositAddress, (String address) {
    //   if (depositKey.currentState!.addressController.text != address) {
    //     depositKey.currentState!.addressController.text = address;
    //   }
    // });
    //
    // reaction((_) => exchangeViewModel.isDepositAddressEnabled, (bool isEnabled) {
    //   depositKey.currentState!.isAddressEditable(isEditable: isEnabled);
    // });
    //
    // reaction((_) => exchangeViewModel.receiveAmount, (String amount) {
    //   if (receiveKey.currentState!.amountController.text != amount) {
    //     receiveKey.currentState!.amountController.text = amount;
    //   }
    // });
    //
    // reaction((_) => exchangeViewModel.receiveAddress, (String address) {
    //   if (receiveKey.currentState!.addressController.text != address) {
    //     receiveKey.currentState!.addressController.text = address;
    //   }
    // });
    //
    // reaction((_) => exchangeViewModel.isReceiveAmountEditable, (bool isReceiveAmountEditable) {
    //   receiveKey.currentState!.isAmountEditable(isEditable: isReceiveAmountEditable);
    // });
    //
    // reaction((_) => exchangeViewModel.tradeState, (ExchangeTradeState state) {
    //   if (state is TradeIsCreatedFailure) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       showPopUp<void>(
    //           context: context,
    //           builder: (BuildContext context) {
    //             return AlertWithOneAction(
    //                 alertTitle: S.of(context).provider_error(state.title),
    //                 alertContent: state.error,
    //                 buttonText: S.of(context).ok,
    //                 buttonAction: () => Navigator.of(context).pop());
    //           });
    //     });
    //   }
    //   if (state is TradeIsCreatedSuccessfully) {
    //     exchangeViewModel.reset();
    //     (exchangeViewModel.tradesStore.trade?.provider == ExchangeProviderDescription.thorChain)
    //         ? Navigator.of(context).pushReplacementNamed(Routes.exchangeTrade)
    //         : Navigator.of(context).pushReplacementNamed(Routes.exchangeConfirm);
    //   }
    // });
    //
    // reaction((_) => exchangeViewModel.limitsState, (LimitsState state) {
    //   String? min;
    //   String? max;
    //
    //   if (state is LimitsLoadedSuccessfully) {
    //     min = state.limits.min != null ? state.limits.min.toString() : null;
    //     max = state.limits.max != null ? state.limits.max.toString() : null;
    //   }
    //
    //   if (state is LimitsLoadedFailure) {
    //     min = '0';
    //     max = '0';
    //   }
    //
    //   if (state is LimitsIsLoading) {
    //     min = '...';
    //     max = '...';
    //   }
    //
    //   if (exchangeViewModel.isFixedRateMode) {
    //     depositKey.currentState!.changeLimits(min: null, max: null);
    //     receiveKey.currentState!.changeLimits(min: min, max: max);
    //   } else {
    //     depositKey.currentState!.changeLimits(min: min, max: max);
    //     receiveKey.currentState!.changeLimits(min: null, max: null);
    //   }
    // });
    //
    // depositAddressController
    //     .addListener(() => exchangeViewModel.depositAddress = depositAddressController.text);
    //
    // depositAmountController.addListener(() {
    //   if (depositAmountController.text != exchangeViewModel.depositAmount &&
    //       depositAmountController.text != S.of(context).all) {
    //     exchangeViewModel.isSendAllEnabled = false;
    //     final isThorChain = exchangeViewModel.selectedProviders
    //         .any((provider) => provider is ThorChainExchangeProvider);
    //
    //     _depositAmountDebounce = isThorChain
    //         ? Debounce(Duration(milliseconds: 1000))
    //         : Debounce(Duration(milliseconds: 500));
    //
    //     _depositAmountDebounce.run(() {
    //       exchangeViewModel.changeDepositAmount(amount: depositAmountController.text);
    //       exchangeViewModel.isReceiveAmountEntered = false;
    //     });
    //   }
    // });
    //
    // receiveAddressController
    //     .addListener(() => exchangeViewModel.receiveAddress = receiveAddressController.text);
    //
    // receiveAmountController.addListener(() {
    //   if (receiveAmountController.text != exchangeViewModel.receiveAmount) {
    //     _receiveAmountDebounce.run(() {
    //       exchangeViewModel.changeReceiveAmount(amount: receiveAmountController.text);
    //       exchangeViewModel.isReceiveAmountEntered = true;
    //     });
    //   }
    // });
    //
    // reaction((_) => exchangeViewModel.wallet.walletAddresses.address, (String address) {
    //   if (exchangeViewModel.depositCurrency == CryptoCurrency.xmr) {
    //     depositKey.currentState!.changeAddress(address: address);
    //   }
    //
    //   if (exchangeViewModel.receiveCurrency == CryptoCurrency.xmr) {
    //     receiveKey.currentState!.changeAddress(address: address);
    //   }
    // });
    //
    // _depositAddressFocus.addListener(() async {
    //   if (!_depositAddressFocus.hasFocus && depositAddressController.text.isNotEmpty) {
    //     final domain = depositAddressController.text;
    //     exchangeViewModel.depositAddress =
    //         await fetchParsedAddress(context, domain, exchangeViewModel.depositCurrency);
    //   }
    // });
    //
    // _receiveAddressFocus.addListener(() async {
    //   if (!_receiveAddressFocus.hasFocus && receiveAddressController.text.isNotEmpty) {
    //     final domain = receiveAddressController.text;
    //     exchangeViewModel.receiveAddress =
    //         await fetchParsedAddress(context, domain, exchangeViewModel.receiveCurrency);
    //   }
    // });
    //
    // _receiveAmountFocus.addListener(() {
    //   if (_receiveAmountFocus.hasFocus) {
    //     exchangeViewModel.enableFixedRateMode();
    //   }
    //   // exchangeViewModel.changeReceiveAmount(amount: receiveAmountController.text);
    // });
    //
    // _depositAmountFocus.addListener(() {
    //   exchangeViewModel.isFixedRateMode = false;
    //   // exchangeViewModel.changeDepositAmount(
    //   //   amount: depositAmountController.text);
    // });

    _isReactionsSet = true;
  }

  void _onCryptoCurrencyChange(CryptoCurrency currency, BuySellViewModel buySellViewModel,
      GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == buySellViewModel.wallet.currency;

    key.currentState!.changeSelectedCurrency(currency);
    key.currentState!.changeWalletName(isCurrentTypeWallet ? buySellViewModel.wallet.name : '');

    key.currentState!.changeAddress(
        address: isCurrentTypeWallet ? buySellViewModel.wallet.walletAddresses.address : '');

    key.currentState!.changeAmount(amount: '');
  }

  void _onFiatCurrencyChange(
      FiatCurrency currency, BuySellViewModel buySellViewModel, GlobalKey<ExchangeCardState> key) {
    key.currentState!.changeSelectedCurrency(currency);
    key.currentState!.changeAmount(amount: '');
  }

  void _onWalletNameChange(ExchangeViewModel exchangeViewModel, CryptoCurrency currency,
      GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == exchangeViewModel.wallet.currency;

    if (isCurrentTypeWallet) {
      key.currentState!.changeWalletName(exchangeViewModel.wallet.name);
      key.currentState!.addressController.text = exchangeViewModel.wallet.walletAddresses.address;
    } else if (key.currentState!.addressController.text ==
        exchangeViewModel.wallet.walletAddresses.address) {
      key.currentState!.changeWalletName('');
      key.currentState!.addressController.text = '';
    }
  }

  Future<String> fetchParsedAddress(
      BuildContext context, String domain, CryptoCurrency currency) async {
    final parsedAddress = await getIt.get<AddressResolver>().resolve(context, domain, currency);
    final address = await extractAddressFromParsed(context, parsedAddress);
    return address;
  }

  void _showFeeAlert(BuildContext context) async {
    await Future<void>.delayed(Duration(seconds: 1));
    final confirmed = await showPopUp<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertWithTwoActions(
                  alertTitle: S.of(context).low_fee,
                  alertContent: S.of(context).low_fee_alert,
                  leftButtonText: S.of(context).ignor,
                  rightButtonText: S.of(context).use_suggested,
                  actionLeftButton: () => Navigator.of(dialogContext).pop(false),
                  actionRightButton: () => Navigator.of(dialogContext).pop(true));
            }) ??
        false;
    if (confirmed) {}
  }

  void disposeBestRateSync() => {};

  Widget _exchangeCardsSection(BuildContext context) {
    final firstExchangeCard = Observer(
        builder: (_) => ExchangeCard(
              onDispose: disposeBestRateSync,
              hasAllAmount: false,
              isAllAmountEnabled: false,
              amountFocusNode: _depositAmountFocus,
              addressFocusNode: _depositAddressFocus,
              key: cryptoCurrencyKey,
              title: 'FIAT ${S.of(context).amount}',
              initialCurrency: buySellViewModel.cryptoCurrency,
              initialWalletName: 'depositWalletName' ?? '',
              initialAddress: "--initialAddress--",
              initialIsAmountEditable: true,
              initialIsAddressEditable: true,
              isAmountEstimated: false,
              hasRefundAddress: true,
              isMoneroWallet: true,
              currencies: buySellViewModel.cryptoCurrencies,
              onCurrencySelected: (currency) =>
                  buySellViewModel.changeCryptoCurrency(currency: currency),
              imageArrow: arrowBottomPurple,
              currencyButtonColor: Colors.transparent,
              addressButtonsColor:
                  Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
              borderColor:
                  Theme.of(context).extension<ExchangePageTheme>()!.textFieldBorderTopPanelColor,
              currencyValueValidator: (value) {
                return null;
              },
              addressTextFieldValidator: AddressValidator(type: buySellViewModel.cryptoCurrency),
              onPushPasteButton: (context) async {},
              onPushAddressBookButton: (context) async {},
            ));

    final secondExchangeCard = Observer(
        builder: (_) => ExchangeCard(
              onDispose: disposeBestRateSync,
              amountFocusNode: _receiveAmountFocus,
              addressFocusNode: _receiveAddressFocus,
              key: fiatCurrencyKey,
              title: 'Crypto ${S.of(context).amount}',
              initialCurrency: buySellViewModel.fiatCurrency,
              initialWalletName: 'receiveWalletName' ?? '',
              initialAddress: "--initialAddress--",
              initialIsAmountEditable: true,
              isAmountEstimated: true,
              isMoneroWallet: true,
              currencies: buySellViewModel.fiatCurrencies,
              onCurrencySelected: (currency) =>
                  buySellViewModel.changeFiatCurrency(currency: currency),
              imageArrow: arrowBottomCakeGreen,
              currencyButtonColor: Colors.transparent,
              addressButtonsColor:
                  Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
              borderColor:
                  Theme.of(context).extension<ExchangePageTheme>()!.textFieldBorderBottomPanelColor,
              currencyValueValidator: (value) {
                return null;
              },
              addressTextFieldValidator: AddressValidator(type: CryptoCurrency.xmr),
              onPushPasteButton: (context) async {},
              onPushAddressBookButton: (context) async {},
            ));

    if (responsiveLayoutUtil.shouldRenderMobileUI) {
      return MobileExchangeCardsSection(
        firstExchangeCard: firstExchangeCard,
        secondExchangeCard: secondExchangeCard,
        isBuySellOption: true,
      );
    }

    return DesktopExchangeCardsSection(
      firstExchangeCard: firstExchangeCard,
      secondExchangeCard: secondExchangeCard,
    );
  }
}
