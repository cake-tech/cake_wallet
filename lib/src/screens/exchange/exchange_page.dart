import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/src/stores/exchange/limits_state.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/exchange_card.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class ExchangePage extends BasePage {
  String get title => S.current.exchange;

  @override
  bool get isModalBackButton => true;

  final Image arrowBottomPurple = Image.asset(
    'assets/images/arrow_bottom_purple_icon.png',
    height: 8,
  );

  @override
  Widget middle(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);

    return FlatButton(
      onPressed: () => _presentProviderPicker(context),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(S.of(context).exchange,
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).primaryTextTheme.title.color)),
                SizedBox(width: 5),
                arrowBottomPurple
              ]),
          Observer(
              builder: (_) => Text('${exchangeStore.provider.title}',
                  style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w400,
                      color:
                          Theme.of(context).primaryTextTheme.headline.color)))
        ],
      ),
    );
  }

  @override
  Widget trailing(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);

    return ButtonTheme(
      minWidth: double.minPositive,
      child: FlatButton(
          padding: EdgeInsets.all(0),
          child: Text(
            S.of(context).clear,
            style: TextStyle(
                color: Theme.of(context).accentTextTheme.caption.color,
                fontWeight: FontWeight.w500,
                fontSize: 16),
          ),
          onPressed: () => exchangeStore.reset()),
    );
  }

  @override
  Widget body(BuildContext context) => ExchangeForm();

  void _presentProviderPicker(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);
    final items = exchangeStore.providersForCurrentPair();
    final selectedItem = items.indexOf(exchangeStore.provider);

    showDialog(
        builder: (_) => Picker(
            items: items,
            selectedAtIndex: selectedItem,
            title: S.of(context).change_exchange_provider,
            onItemSelected: (provider) =>
                exchangeStore.changeProvider(provider: provider)),
        context: context);
  }
}

class ExchangeForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ExchangeFormState();
}

class ExchangeFormState extends State<ExchangeForm> {
  final depositKey = GlobalKey<ExchangeCardState>();
  final receiveKey = GlobalKey<ExchangeCardState>();
  final _formKey = GlobalKey<FormState>();
  var _isReactionsSet = false;

  final Image arrowBottomPurple = Image.asset(
    'assets/images/arrow_bottom_purple_icon.png',
    height: 8,
  );
  final Image arrowBottomCakeGreen = Image.asset(
    'assets/images/arrow_bottom_cake_green.png',
    height: 8,
  );

  @override
  Widget build(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);
    final walletStore = Provider.of<WalletStore>(context);

    final depositWalletName =
        exchangeStore.depositCurrency == CryptoCurrency.xmr
            ? walletStore.name
            : null;
    final receiveWalletName =
        exchangeStore.receiveCurrency == CryptoCurrency.xmr
            ? walletStore.name
            : null;

    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _setReactions(context, exchangeStore, walletStore));

    return Form(
        key: _formKey,
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(left: 20, right: 20),
          content: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 20),
                  child: Text(
                    S.of(context).you_will_send,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.1,
                        color: Theme.of(context).primaryTextTheme.title.color),
                  ),
                ),
                ExchangeCard(
                  key: depositKey,
                  initialCurrency: exchangeStore.depositCurrency,
                  initialWalletName: depositWalletName,
                  initialAddress:
                      exchangeStore.depositCurrency == walletStore.type
                          ? walletStore.address
                          : null,
                  initialIsAmountEditable:
                      !(exchangeStore.provider is XMRTOExchangeProvider),
                  initialIsAddressEditable:
                      !(exchangeStore.provider is XMRTOExchangeProvider),
                  isAmountEstimated:
                      exchangeStore.provider is XMRTOExchangeProvider,
                  currencies: CryptoCurrency.all,
                  onCurrencySelected: (currency) =>
                      exchangeStore.changeDepositCurrency(currency: currency),
                  imageArrow: arrowBottomPurple,
                  currencyValueValidator: (value) {
                    exchangeStore.validateCryptoCurrency(value);
                    return exchangeStore.errorMessage;
                  },
                  addressTextFieldValidator: (value) {
                    exchangeStore.validateAddress(value,
                        cryptoCurrency: exchangeStore.depositCurrency);
                    return exchangeStore.errorMessage;
                  },
                ),
                SizedBox(height: 35),
                Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      S.of(context).you_will_get,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          height: 1.1,
                          color:
                              Theme.of(context).primaryTextTheme.title.color),
                    )),
                Observer(
                    builder: (_) => ExchangeCard(
                          key: receiveKey,
                          initialCurrency: exchangeStore.receiveCurrency,
                          initialWalletName: receiveWalletName,
                          initialAddress:
                              exchangeStore.receiveCurrency == walletStore.type
                                  ? walletStore.address
                                  : null,
                          initialIsAmountEditable:
                              exchangeStore.provider is XMRTOExchangeProvider,
                          initialIsAddressEditable:
                              exchangeStore.provider is XMRTOExchangeProvider,
                          isAmountEstimated: !(exchangeStore.provider
                              is XMRTOExchangeProvider),
                          currencies: CryptoCurrency.all,
                          onCurrencySelected: (currency) => exchangeStore
                              .changeReceiveCurrency(currency: currency),
                          imageArrow: arrowBottomCakeGreen,
                          currencyValueValidator: (value) {
                            exchangeStore.validateCryptoCurrency(value);
                            return exchangeStore.errorMessage;
                          },
                          addressTextFieldValidator: (value) {
                            exchangeStore.validateAddress(value,
                                cryptoCurrency: exchangeStore.receiveCurrency);
                            return exchangeStore.errorMessage;
                          },
                        )),
              ],
            ),
          ),
          bottomSectionPadding: EdgeInsets.only(top: 35, left: 20, right: 20),
          bottomSection: Column(children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Observer(builder: (_) {
                final description =
                    exchangeStore.provider is XMRTOExchangeProvider
                        ? S.of(context).amount_is_guaranteed
                        : S.of(context).amount_is_estimate;
                return Center(
                  child: Text(
                    description,
                    style: TextStyle(color: Palette.blueGrey, fontSize: 12),
                  ),
                );
              }),
            ),
            Observer(
                builder: (_) => LoadingPrimaryButton(
                      text: S.of(context).exchange,
                      onPressed: () {
                        if (_formKey.currentState.validate())
                          exchangeStore.createTrade();
                      },
                      color: Theme.of(context)
                          .primaryTextTheme
                          .button
                          .backgroundColor,
                      borderColor: Theme.of(context)
                          .primaryTextTheme
                          .button
                          .decorationColor,
                      isLoading: exchangeStore.tradeState is TradeIsCreating,
                    )),
            Observer(builder: (_) {
              final title = exchangeStore.provider.description.title;
              var imageSrc = '';

              switch (exchangeStore.provider.description) {
                case ExchangeProviderDescription.xmrto:
                  imageSrc = 'assets/images/xmr_btc.png';
                  break;
                case ExchangeProviderDescription.changeNow:
                  imageSrc = 'assets/images/change_now.png';
                  break;
              }

              return Padding(
                padding: EdgeInsets.only(top: 20, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(imageSrc),
                    SizedBox(width: 10),
                    Text(
                      S.of(context).powered_by(title),
                      style: TextStyle(fontSize: 14, color: Palette.powered),
                    )
                  ],
                ),
              );
            })
          ]),
        ));
  }

  void _setReactions(
      BuildContext context, ExchangeStore store, WalletStore walletStore) {
    if (_isReactionsSet) {
      return;
    }

    final depositAddressController = depositKey.currentState.addressController;
    final depositAmountController = depositKey.currentState.amountController;
    final receiveAddressController = receiveKey.currentState.addressController;
    final receiveAmountController = receiveKey.currentState.amountController;
    final limitsState = store.limitsState;

    if (limitsState is LimitsLoadedSuccessfully) {
      final min = limitsState.limits.min != null
          ? limitsState.limits.min.toString()
          : null;
      final max = limitsState.limits.max != null
          ? limitsState.limits.max.toString()
          : null;
      final key =
          store.provider is XMRTOExchangeProvider ? receiveKey : depositKey;
      key.currentState.changeLimits(min: min, max: max);
    }

    _onCurrencyChange(store.receiveCurrency, walletStore, receiveKey);
    _onCurrencyChange(store.depositCurrency, walletStore, depositKey);

    reaction(
        (_) => walletStore.name,
        (_) => _onWalletNameChange(
            walletStore, store.receiveCurrency, receiveKey));

    reaction(
        (_) => walletStore.name,
        (_) => _onWalletNameChange(
            walletStore, store.depositCurrency, depositKey));

    reaction((_) => store.receiveCurrency,
        (currency) => _onCurrencyChange(currency, walletStore, receiveKey));

    reaction((_) => store.depositCurrency,
        (currency) => _onCurrencyChange(currency, walletStore, depositKey));

    reaction((_) => store.depositAmount, (amount) {
      if (depositKey.currentState.amountController.text != amount) {
        depositKey.currentState.amountController.text = amount;
      }
    });

    reaction((_) => store.receiveAmount, (amount) {
      if (receiveKey.currentState.amountController.text !=
          store.receiveAmount) {
        receiveKey.currentState.amountController.text = amount;
      }
    });

    reaction((_) => store.provider, (provider) {
      final isReversed = provider is XMRTOExchangeProvider;

      if (isReversed) {
        receiveKey.currentState.isAddressEditable(isEditable: true);
        receiveKey.currentState.isAmountEditable(isEditable: true);
        depositKey.currentState.isAddressEditable(isEditable: false);
        depositKey.currentState.isAmountEditable(isEditable: false);
      } else {
        receiveKey.currentState.isAddressEditable(isEditable: true);
        receiveKey.currentState.isAmountEditable(isEditable: false);
        depositKey.currentState.isAddressEditable(isEditable: true);
        depositKey.currentState.isAmountEditable(isEditable: true);
      }

      depositKey.currentState.changeIsAmountEstimated(isReversed);
      receiveKey.currentState.changeIsAmountEstimated(!isReversed);
    });

    reaction((_) => store.tradeState, (state) {
      if (state is TradeIsCreatedFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(S.of(context).error),
                  content: Text(state.error),
                  actions: <Widget>[
                    FlatButton(
                        child: Text(S.of(context).ok),
                        onPressed: () => Navigator.of(context).pop())
                  ],
                );
              });
        });
      }
      if (state is TradeIsCreatedSuccessfully) {
        Navigator.of(context)
            .pushNamed(Routes.exchangeConfirm, arguments: state.trade);
      }
    });

    reaction((_) => store.limitsState, (state) {
      final isXMRTO = store.provider is XMRTOExchangeProvider;
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

      final depositMin = isXMRTO ? null : min;
      final depositMax = isXMRTO ? null : max;
      final receiveMin = isXMRTO ? min : null;
      final receiveMax = isXMRTO ? max : null;

      depositKey.currentState.changeLimits(min: depositMin, max: depositMax);
      receiveKey.currentState.changeLimits(min: receiveMin, max: receiveMax);
    });

    depositAddressController.addListener(
        () => store.depositAddress = depositAddressController.text);

    depositAmountController.addListener(() {
      if (depositAmountController.text != store.depositAmount) {
        store.changeDepositAmount(amount: depositAmountController.text);
      }
    });

    receiveAddressController.addListener(
        () => store.receiveAddress = receiveAddressController.text);

    receiveAmountController.addListener(() {
      if (receiveAmountController.text != store.receiveAmount) {
        store.changeReceiveAmount(amount: receiveAmountController.text);
      }
    });

    reaction((_) => walletStore.address, (address) {
      if (store.depositCurrency == CryptoCurrency.xmr) {
        depositKey.currentState.changeAddress(address: address);
      }

      if (store.receiveCurrency == CryptoCurrency.xmr) {
        receiveKey.currentState.changeAddress(address: address);
      }
    });

    _isReactionsSet = true;
  }

  void _onCurrencyChange(CryptoCurrency currency, WalletStore walletStore,
      GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == walletStore.type;

    key.currentState.changeSelectedCurrency(currency);
    key.currentState
        .changeWalletName(isCurrentTypeWallet ? walletStore.name : null);

    key.currentState
        .changeAddress(address: isCurrentTypeWallet ? walletStore.address : '');

    key.currentState.changeAmount(amount: '');
  }

  void _onWalletNameChange(WalletStore walletStore, CryptoCurrency currency,
      GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == walletStore.type;

    if (isCurrentTypeWallet) {
      key.currentState.changeWalletName(walletStore.name);
      key.currentState.addressController.text = walletStore.address;
    } else if (key.currentState.addressController.text == walletStore.address) {
      key.currentState.changeWalletName(null);
      key.currentState.addressController.text = null;
    }
  }
}
