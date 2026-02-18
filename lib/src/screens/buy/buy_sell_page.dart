import 'package:cake_wallet/buy/sell_buy_states.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/di.dart';
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
      color: Theme.of(context).colorScheme.primary,
      size: 16,
    );
    final _closeButton = currentTheme.isDark ? closeButtonImageDarkTheme : closeButtonImage;

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
                overlayColor: WidgetStateColor.resolveWith((states) => Colors.transparent),
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
          keyboardBarColor: Theme.of(context).colorScheme.surface,
          nextFocus: false,
          actions: [
            KeyboardActionsItem(
                focusNode: _fiatAmountFocus, toolbarButtons: [(_) => KeyboardDoneButton()]),
            KeyboardActionsItem(
                focusNode: _cryptoAmountFocus, toolbarButtons: [(_) => KeyboardDoneButton()])
          ]),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Form(
          key: _formKey,
          child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: Observer(
              builder: (_) => Column(
                children: [
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
                ],
              ),
            ),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: Observer(
              builder: (_) => Column(
                children: [
                  if (buySellViewModel.isBuySellQuoteFailed)
                    Padding(
                      padding: EdgeInsets.only(bottom: 15),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Theme.of(context).colorScheme.error,
                                size: 26,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 8,
                            child: Text(
                              buySellViewModel.buySellQuoteFailedError ??
                                  S.of(context).buy_sell_pair_is_not_supported_warning,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  LoadingPrimaryButton(
                    text: S.current.choose_a_provider,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      buySellViewModel.onTapChoseProvider(context);
                    },
                    color: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    isDisabled: buySellViewModel.isBuySellQuoteFailed,
                    isLoading:
                        !buySellViewModel.isReadyToTrade && !buySellViewModel.isBuySellQuoteFailed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          isDarkTheme: currentTheme.isDark);
    }
    if (buySellViewModel.paymentMethodState is PaymentMethodFailed) {
      return OptionTilePlaceholder(errorText: 'No payment methods available', borderRadius: 30);
    }
    if (buySellViewModel.paymentMethodState is PaymentMethodLoaded &&
        buySellViewModel.selectedPaymentMethod != null) {
      final selectedPaymentMethod = buySellViewModel.selectedPaymentMethod!;
      return ProviderOptionTile(
        lightImagePath: selectedPaymentMethod.lightIconPath,
        darkImagePath: selectedPaymentMethod.darkIconPath,
        title: selectedPaymentMethod.title,
        onPressed: () => _pickPaymentMethod(context),
        leadingIcon: Icons.arrow_forward_ios,
        isLightMode: !currentTheme.isDark,
        borderRadius: 30,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
      );
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
    if (_isReactionsSet) return;

    final fiatAmountController = fiatCurrencyKey.currentState!.amountController;
    final cryptoAmountController = cryptoCurrencyKey.currentState!.amountController;
    final cryptoAddressController = cryptoCurrencyKey.currentState!.addressController;

    _onCurrencyChange(buySellViewModel.cryptoCurrency, buySellViewModel, cryptoCurrencyKey);
    _onCurrencyChange(buySellViewModel.fiatCurrency, buySellViewModel, fiatCurrencyKey);

    reaction(
        (_) => buySellViewModel.wallet.name,
        (_) => _onWalletNameChange(
            buySellViewModel, buySellViewModel.cryptoCurrency, cryptoCurrencyKey));

    reaction(
        (_) => buySellViewModel.cryptoCurrency,
        (currency) => _onCurrencyChange(currency, buySellViewModel, cryptoCurrencyKey));

    reaction((_) => buySellViewModel.fiatCurrency,
        (currency) => _onCurrencyChange(currency, buySellViewModel, fiatCurrencyKey));

    reaction((_) => buySellViewModel.fiatAmount, (amount) {
      if (fiatCurrencyKey.currentState!.amountController.text != amount) {
        fiatCurrencyKey.currentState!.amountController.text = amount;
      }
    });

    reaction((_) => buySellViewModel.isCryptoCurrencyAddressEnabled, (isEnabled) {
      cryptoCurrencyKey.currentState!.isAddressEditable(isEditable: isEnabled);
    });

    reaction((_) => buySellViewModel.cryptoAmount, (amount) {
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
        buySellViewModel.cryptoCurrencyAddress = await fetchParsedAddress(
            context, domain, buySellViewModel.cryptoCurrency);
      }
    });

    reaction((_) => buySellViewModel.wallet.walletAddresses.addressForExchange, (String address) {
      if (buySellViewModel.cryptoCurrency == CryptoCurrency.xmr) {
        cryptoCurrencyKey.currentState!.changeAddress(address: address);
      }
    });

    reaction((_) => buySellViewModel.isReadyToTrade, (bool isReady) {
      if (isReady) {
        if (buySellViewModel.skipIsReadyToTradeReaction) {
          buySellViewModel.skipIsReadyToTradeReaction = false;
          return;
        }
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

  void _onCurrencyChange(
      Currency currency, BuySellViewModel buySellViewModel, GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == buySellViewModel.wallet.currency;

    key.currentState!.changeSelectedCurrency(currency);
    key.currentState!.changeWalletName(isCurrentTypeWallet ? buySellViewModel.wallet.name : '');

    key.currentState!.changeAddress(
        address:
            isCurrentTypeWallet ? buySellViewModel.wallet.walletAddresses.addressForExchange : '');

    key.currentState!.changeAmount(amount: '');
  }

  void _onWalletNameChange(BuySellViewModel buySellViewModel, CryptoCurrency currency,
      GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == buySellViewModel.wallet.currency;

    if (isCurrentTypeWallet) {
      key.currentState!.changeWalletName(buySellViewModel.wallet.name);
      key.currentState!.addressController.text =
          buySellViewModel.wallet.walletAddresses.addressForExchange;
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
        onCurrencySelected: (currency) => buySellViewModel.changeFiatCurrency(currency: currency),
        imageArrow: Image.asset(
          'assets/images/arrow_bottom_purple_icon.png',
          color: Theme.of(context).colorScheme.primary,
          height: 8,
        ),
        currencyButtonColor: Colors.transparent,
        addressButtonsColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderColor: Theme.of(context).colorScheme.outlineVariant,
        onPushPasteButton: (context) async {},
        onPushAddressBookButton: (context) async {},
        fillColor: buySellViewModel.isBuyAction
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.surfaceContainerLow,
      ),
    );

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
        onCurrencySelected: (currency) => buySellViewModel.changeCryptoCurrency(currency: currency),
        imageArrow: Image.asset(
          'assets/images/arrow_bottom_cake_green.png',
          color: Theme.of(context).colorScheme.primary,
          height: 8,
        ),
        currencyButtonColor: Colors.transparent,
        addressButtonsColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderColor: Theme.of(context).colorScheme.outlineVariant,
        addressTextFieldValidator: AddressValidator(type: buySellViewModel.cryptoCurrency),
        onPushPasteButton: (context) async {},
        onPushAddressBookButton: (context) async {},
        fillColor: buySellViewModel.isBuyAction
            ? Theme.of(context).colorScheme.surfaceContainerLow
            : Theme.of(context).colorScheme.surfaceContainer,
        useSatoshis: buySellViewModel.useSatoshi,
      ),
    );

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
            onBuyTap: () => null,
            onSellTap: () =>
                buySellViewModel.isBuyAction ? buySellViewModel.changeBuySellAction() : null,
            isBuySellOption: true,
          );
        } else {
          return DesktopExchangeCardsSection(
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

  Future<String> fetchParsedAddress(
    BuildContext context,
    String domain,
    CryptoCurrency currency,
  ) async {
    final parsedAddress =
        await getIt.get<AddressResolver>().resolve(context, domain, currency);
    final address = await extractAddressFromParsed(context, parsedAddress);
    return address;
  }
}
