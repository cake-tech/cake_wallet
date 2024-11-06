import 'package:cake_wallet/buy/sell_buy_states.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/desktop_exchange_cards_section.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/exchange_card.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/mobile_exchange_cards_section.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/provider_optoin_tile.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/src/screens/send/widgets/extract_address_from_parsed.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/buy/buy_sell_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';

class BuySellPage extends BasePage {
  BuySellPage(this.buySellViewModel);

  final BuySellViewModel buySellViewModel;
  final cryptoCurrencyKey = GlobalKey<ExchangeCardState>();
  final fiatCurrencyKey = GlobalKey<ExchangeCardState>();
  final _formKey = GlobalKey<FormState>();
  final _fiatAmountFocus = FocusNode();
  final _cryptoAmountFocus = FocusNode();
  final _cryptoAddressFocus = FocusNode();
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
        buySellViewModel.reset();
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
                  focusNode: _fiatAmountFocus, toolbarButtons: [(_) => KeyboardDoneButton()]),
              KeyboardActionsItem(
                  focusNode: _cryptoAmountFocus, toolbarButtons: [(_) => KeyboardDoneButton()])
            ]),
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: Form(
              key: _formKey,
              child: ScrollableWithBottomSection(
                contentPadding: EdgeInsets.only(bottom: 24),
                content: Observer(
                    builder: (_) => Column(children: [
                          _exchangeCardsSection(context),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                SizedBox(height: 12),
                                _buildPaymentMethodTile(context),
                              ],
                            ),
                          ),
                        ])),
                bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
                bottomSection: Column(children: [
                  Observer(
                      builder: (_) => LoadingPrimaryButton(
                          text: S.current.choose_a_provider,
                          onPressed: () async {
                            if(!_formKey.currentState!.validate()) return;
                            buySellViewModel.onTapChoseProvider(context);
                          },
                          color: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                          isDisabled: false,
                          isLoading: !buySellViewModel.isReadyToTrade)),
                ]),
              )),
        ));
  }

  Widget _buildPaymentMethodTile(BuildContext context) {
    if (buySellViewModel.paymentMethodState is PaymentMethodLoading ||
        buySellViewModel.paymentMethodState is InitialPaymentMethod) {
      return OptionTilePlaceholder(
          withBadge: false,
          withSubtitle: false,
          borderRadius: 30,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leadingIcon: Icons.arrow_forward_ios,
          isDarkTheme: buySellViewModel.isDarkTheme);
    }
    if (buySellViewModel.paymentMethodState is PaymentMethodFailed) {
      return OptionTilePlaceholder(errorText: 'No payment methods available', borderRadius: 30);
    }
    if (buySellViewModel.paymentMethodState is PaymentMethodLoaded &&
        buySellViewModel.selectedPaymentMethod != null) {
      return Observer(builder: (_) {
        final selectedPaymentMethod = buySellViewModel.selectedPaymentMethod!;
        return ProviderOptionTile(
          lightImagePath: selectedPaymentMethod.lightIconPath,
          darkImagePath: selectedPaymentMethod.darkIconPath,
          title: selectedPaymentMethod.title,
          onPressed: () => _pickPaymentMethod(context),
          leadingIcon: Icons.arrow_forward_ios,
          isLightMode: !buySellViewModel.isDarkTheme,
          borderRadius: 30,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          titleTextStyle:
          textLargeBold(color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
        );
      });
    }
    return OptionTilePlaceholder(errorText: 'No payment methods available', borderRadius: 30);
  }

  void _pickPaymentMethod(BuildContext context) async {
    final currentOption = buySellViewModel.selectedPaymentMethod;
    await Navigator.of(context).pushNamed(
      Routes.paymentMethodOptionsPage,
      arguments: [
        buySellViewModel.paymentMethods,
        buySellViewModel.changeOption,
      ],
    );

    buySellViewModel.selectedPaymentMethod;
    if (currentOption != null &&
        currentOption.paymentMethodType !=
            buySellViewModel.selectedPaymentMethod?.paymentMethodType) {
      await buySellViewModel.calculateBestRate();
    }
  }

  void _setReactions(BuildContext context, BuySellViewModel buySellViewModel) {
    if (_isReactionsSet) {
      return;
    }

    final fiatAmountController = fiatCurrencyKey.currentState!.amountController;
    final cryptoAmountController = cryptoCurrencyKey.currentState!.amountController;
    final cryptoAddressController = cryptoCurrencyKey.currentState!.addressController;

    _onCurrencyChange(buySellViewModel.cryptoCurrency, buySellViewModel, cryptoCurrencyKey);
    _onCurrencyChange(buySellViewModel.fiatCurrency, buySellViewModel, fiatCurrencyKey);

    reaction(
            (_) => buySellViewModel.wallet.name,
            (String _) =>
            _onWalletNameChange(buySellViewModel, buySellViewModel.cryptoCurrency, cryptoCurrencyKey));

    reaction(
        (_) => buySellViewModel.cryptoCurrency,
        (CryptoCurrency currency) =>
            _onCurrencyChange(currency, buySellViewModel, cryptoCurrencyKey));

    reaction(
        (_) => buySellViewModel.fiatCurrency,
        (FiatCurrency currency) =>
            _onCurrencyChange(currency, buySellViewModel, fiatCurrencyKey));

    reaction((_) => buySellViewModel.fiatAmount, (String amount) {
      if (fiatCurrencyKey.currentState!.amountController.text != amount) {
        fiatCurrencyKey.currentState!.amountController.text = amount;
      }
    });

    reaction((_) => buySellViewModel.isCryptoCurrencyAddressEnabled, (bool isEnabled) {
      cryptoCurrencyKey.currentState!.isAddressEditable(isEditable: isEnabled);
    });

    reaction((_) => buySellViewModel.cryptoAmount, (String amount) {
      if (cryptoCurrencyKey.currentState!.amountController.text != amount) {
        cryptoCurrencyKey.currentState!.amountController.text = amount;
      }
    });

    reaction((_) => buySellViewModel.cryptoCurrencyAddress, (String address) {
      if (cryptoAddressController != address) {
        cryptoCurrencyKey.currentState!.addressController.text = address;
      }
    });

    fiatAmountController.addListener(() {
      if (fiatAmountController.text != buySellViewModel.fiatAmount) {
          buySellViewModel.changeFiatAmount(amount: fiatAmountController.text);
      }
    });

    cryptoAmountController.addListener(() {
      if (cryptoAmountController.text != buySellViewModel.cryptoAmount) {
          buySellViewModel.changeCryptoAmount(amount: cryptoAmountController.text);
      }
    });

    cryptoAddressController.addListener(() {
      buySellViewModel.changeCryptoCurrencyAddress(cryptoAddressController.text);
    });

    _cryptoAddressFocus.addListener(() async {
      if (!_cryptoAddressFocus.hasFocus && cryptoAddressController.text.isNotEmpty) {
        final domain = cryptoAddressController.text;
        buySellViewModel.cryptoCurrencyAddress =
        await fetchParsedAddress(context, domain, buySellViewModel.cryptoCurrency);
      }
    });

    reaction((_) => buySellViewModel.wallet.walletAddresses.addressForExchange, (String address) {
      if (buySellViewModel.cryptoCurrency == CryptoCurrency.xmr) {
        cryptoCurrencyKey.currentState!.changeAddress(address: address);
      }
    });

    reaction((_) => buySellViewModel.isReadyToTrade, (bool isReady) {
      if (isReady) {
        if (cryptoAmountController.text.isNotEmpty &&
            cryptoAmountController.text != S.current.fetching) {
          buySellViewModel.changeCryptoAmount(amount: cryptoAmountController.text);
        } else if (fiatAmountController.text.isNotEmpty &&
            fiatAmountController.text != S.current.fetching) {
          buySellViewModel.changeFiatAmount(amount: fiatAmountController.text);
        }
      }
    });

    _isReactionsSet = true;
  }

  void _onCurrencyChange(Currency currency, BuySellViewModel buySellViewModel,
      GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == buySellViewModel.wallet.currency;

    key.currentState!.changeSelectedCurrency(currency);
    key.currentState!.changeWalletName(isCurrentTypeWallet ? buySellViewModel.wallet.name : '');

    key.currentState!.changeAddress(
        address: isCurrentTypeWallet ? buySellViewModel.wallet.walletAddresses.addressForExchange : '');

    key.currentState!.changeAmount(amount: '');
  }

  void _onWalletNameChange(BuySellViewModel buySellViewModel, CryptoCurrency currency,
      GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == buySellViewModel.wallet.currency;

    if (isCurrentTypeWallet) {
      key.currentState!.changeWalletName(buySellViewModel.wallet.name);
      key.currentState!.addressController.text = buySellViewModel.wallet.walletAddresses.addressForExchange;
    } else if (key.currentState!.addressController.text ==
        buySellViewModel.wallet.walletAddresses.addressForExchange) {
      key.currentState!.changeWalletName('');
      key.currentState!.addressController.text = '';
    }
  }

  void disposeBestRateSync() => {};

  Widget _exchangeCardsSection(BuildContext context) {
    final fiatExchangeCard = Observer(
        builder: (_) => ExchangeCard(
              cardInstanceName: 'fiat_currency_trade_card',
              onDispose: disposeBestRateSync,
              amountFocusNode: _fiatAmountFocus,
              key: fiatCurrencyKey,
              title: 'FIAT ${S.of(context).amount}',
              initialCurrency: buySellViewModel.fiatCurrency,
              initialWalletName: '',
              initialAddress: '',
              initialIsAmountEditable: true,
              isAmountEstimated: false,
              currencyRowPadding: EdgeInsets.zero,
              addressRowPadding: EdgeInsets.zero,
              isMoneroWallet: buySellViewModel.wallet == WalletType.monero,
              showAddressField: false,
              showLimitsField: false,
              currencies: buySellViewModel.fiatCurrencies,
              onCurrencySelected: (currency) =>
                  buySellViewModel.changeFiatCurrency(currency: currency),
              imageArrow: arrowBottomPurple,
              currencyButtonColor: Colors.transparent,
              addressButtonsColor:
                  Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
              borderColor:
                  Theme.of(context).extension<ExchangePageTheme>()!.textFieldBorderTopPanelColor,
              onPushPasteButton: (context) async {},
              onPushAddressBookButton: (context) async {},
            ));

    final cryptoExchangeCard = Observer(
        builder: (_) => ExchangeCard(
              cardInstanceName: 'crypto_currency_trade_card',
              onDispose: disposeBestRateSync,
              amountFocusNode: _cryptoAmountFocus,
              addressFocusNode: _cryptoAddressFocus,
              key: cryptoCurrencyKey,
              title: 'Crypto ${S.of(context).amount}',
              initialCurrency: buySellViewModel.cryptoCurrency,
              initialWalletName: '',
              initialAddress: buySellViewModel.cryptoCurrency == buySellViewModel.wallet.currency
                  ? buySellViewModel.wallet.walletAddresses.addressForExchange
                  : buySellViewModel.cryptoCurrencyAddress,
              initialIsAmountEditable: true,
              isAmountEstimated: true,
              showLimitsField: false,
              currencyRowPadding: EdgeInsets.zero,
              addressRowPadding: EdgeInsets.zero,
              isMoneroWallet: buySellViewModel.wallet == WalletType.monero,
              currencies: buySellViewModel.cryptoCurrencies,
              onCurrencySelected: (currency) =>
                  buySellViewModel.changeCryptoCurrency(currency: currency),
              imageArrow: arrowBottomCakeGreen,
              currencyButtonColor: Colors.transparent,
              addressButtonsColor:
                  Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
              borderColor:
                  Theme.of(context).extension<ExchangePageTheme>()!.textFieldBorderBottomPanelColor,
              addressTextFieldValidator: AddressValidator(type: buySellViewModel.cryptoCurrency),
              onPushPasteButton: (context) async {},
              onPushAddressBookButton: (context) async {},
            ));

    if (responsiveLayoutUtil.shouldRenderMobileUI) {
      return Observer(
        builder: (_) {
          if (buySellViewModel.isBuyAction) {
            return MobileExchangeCardsSection(
              firstExchangeCard: fiatExchangeCard,
              secondExchangeCard: cryptoExchangeCard,
              onBuyTap: () => null,
              onSellTap: () =>
                  buySellViewModel.isBuyAction ? buySellViewModel.changeBuySellAction() : null,
              isBuySellOption: true,
            );
          } else {
            return MobileExchangeCardsSection(
              firstExchangeCard: cryptoExchangeCard,
              secondExchangeCard: fiatExchangeCard,
              onBuyTap: () =>
                  !buySellViewModel.isBuyAction ? buySellViewModel.changeBuySellAction() : null,
              onSellTap: () => null,
              isBuySellOption: true,
            );
          }
        },
      );
    }

    return Observer(
      builder: (_) {
        if (buySellViewModel.isBuyAction) {
          return DesktopExchangeCardsSection(
            firstExchangeCard: fiatExchangeCard,
            secondExchangeCard: cryptoExchangeCard,
          );
        } else {
          return DesktopExchangeCardsSection(
            firstExchangeCard: cryptoExchangeCard,
            secondExchangeCard: fiatExchangeCard,
          );
        }
      },
    );
  }

  Future<String> fetchParsedAddress(
      BuildContext context, String domain, CryptoCurrency currency) async {
    final parsedAddress = await getIt.get<AddressResolver>().resolve(context, domain, currency);
    final address = await extractAddressFromParsed(context, parsedAddress);
    return address;
  }
}
