import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/src/stores/exchange/limits_state.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/exchange_card.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/top_panel.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/provider_picker.dart';
import 'package:cake_wallet/src/stores/exchange_template/exchange_template_store.dart';

class ExchangeTemplatePage extends BasePage {
  @override
  String get title => 'New template';

  @override
  Color get backgroundColor => PaletteDark.walletCardSubAddressField;

  final Image arrowBottom =
  Image.asset('assets/images/arrow_bottom_purple_icon.png', color: Colors.white, height: 6);

  @override
  Widget trailing(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);

    return FlatButton(
        onPressed: () => _presentProviderPicker(context),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(S.of(context).exchange,
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: Colors.white)),
                Observer(
                    builder: (_) => Text('${exchangeStore.provider.title}',
                        style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w400,
                            color:PaletteDark.walletCardText)))
              ],
            ),
            SizedBox(width: 5),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: arrowBottom,
            )
          ],
        )
    );
  }

  void _presentProviderPicker(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);
    final items = exchangeStore.providersForCurrentPair();
    final selectedItem = items.indexOf(exchangeStore.provider);

    showDialog<void>(
        builder: (_) => ProviderPicker(
            items: items,
            selectedAtIndex: selectedItem,
            title: S.of(context).change_exchange_provider,
            onItemSelected: (ExchangeProvider provider) =>
                exchangeStore.changeProvider(provider: provider)),
        context: context);
  }

  @override
  Widget body(BuildContext context) => ExchangeTemplateForm();
}

class ExchangeTemplateForm extends StatefulWidget{
  @override
  ExchangeTemplateFormState createState() => ExchangeTemplateFormState();
}

class ExchangeTemplateFormState extends State<ExchangeTemplateForm> {
  final depositKey = GlobalKey<ExchangeCardState>();
  final receiveKey = GlobalKey<ExchangeCardState>();
  final _formKey = GlobalKey<FormState>();
  var _isReactionsSet = false;

  final Image arrowBottomPurple = Image.asset(
    'assets/images/arrow_bottom_purple_icon.png',
    color: Colors.white,
    height: 8,
  );
  final Image arrowBottomCakeGreen = Image.asset(
    'assets/images/arrow_bottom_cake_green.png',
    color: Colors.white,
    height: 8,
  );

  @override
  Widget build(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);
    final walletStore = Provider.of<WalletStore>(context);
    final exchangeTemplateStore = Provider.of<ExchangeTemplateStore>(context);

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

    return Container(
      color: PaletteDark.historyPanel,
      child: Form(
          key: _formKey,
          child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: Column(
              children: <Widget>[
                TopPanel(
                    color: PaletteDark.menuList,
                    edgeInsets: EdgeInsets.only(bottom: 24),
                    widget: Column(
                      children: <Widget>[
                        TopPanel(
                            color: PaletteDark.walletCardSubAddressField,
                            widget: Observer(
                              builder: (_) => ExchangeCard(
                                key: depositKey,
                                title: S.of(context).you_will_send,
                                initialCurrency: exchangeStore.depositCurrency,
                                initialWalletName: depositWalletName,
                                initialAddress:
                                exchangeStore.depositCurrency == walletStore.type
                                    ? walletStore.address
                                    : null,
                                initialIsAmountEditable: true,
                                initialIsAddressEditable: true,
                                isAmountEstimated: false,
                                currencies: CryptoCurrency.all,
                                onCurrencySelected: (currency) =>
                                    exchangeStore.changeDepositCurrency(currency: currency),
                                imageArrow: arrowBottomPurple,
                                currencyButtonColor: PaletteDark.walletCardSubAddressField,
                                addressButtonsColor: PaletteDark.menuList,
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
                            )
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 32, left: 24, right: 24),
                          child: Observer(
                              builder: (_) => ExchangeCard(
                                key: receiveKey,
                                title: S.of(context).you_will_get,
                                initialCurrency: exchangeStore.receiveCurrency,
                                initialWalletName: receiveWalletName,
                                initialAddress:
                                exchangeStore.receiveCurrency == walletStore.type
                                    ? walletStore.address
                                    : null,
                                initialIsAmountEditable: false,
                                initialIsAddressEditable: true,
                                isAmountEstimated: true,
                                currencies: CryptoCurrency.all,
                                onCurrencySelected: (currency) => exchangeStore
                                    .changeReceiveCurrency(currency: currency),
                                imageArrow: arrowBottomCakeGreen,
                                currencyButtonColor: PaletteDark.menuList,
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
                        )
                      ],
                    )
                ),
              ],
            ),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
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
                      style: TextStyle(
                          color: PaletteDark.walletCardText,
                          fontSize: 12
                      ),
                    ),
                  );
                }),
              ),
              PrimaryButton(
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    exchangeTemplateStore.addTemplate(
                      amount: exchangeStore.depositAmount,
                      depositCurrency: exchangeStore.depositCurrency.toString(),
                      receiveCurrency: exchangeStore.receiveCurrency.toString(),
                      provider: exchangeStore.provider.toString(),
                      depositAddress: exchangeStore.depositAddress,
                      receiveAddress: exchangeStore.receiveAddress
                    );
                    exchangeTemplateStore.update();
                    Navigator.of(context).pop();
                  }
                },
                text: S.of(context).save,
                color: Colors.green,
                textColor: Colors.white
              ),
            ]),
          )),
    );
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
      final key = depositKey;
      key.currentState.changeLimits(min: min, max: max);
    }

    _onCurrencyChange(store.receiveCurrency, walletStore, receiveKey);
    _onCurrencyChange(store.depositCurrency, walletStore, depositKey);

    reaction(
            (_) => walletStore.name,
            (String _) => _onWalletNameChange(
            walletStore, store.receiveCurrency, receiveKey));

    reaction(
            (_) => walletStore.name,
            (String _) => _onWalletNameChange(
            walletStore, store.depositCurrency, depositKey));

    reaction(
            (_) => store.receiveCurrency,
            (CryptoCurrency currency) =>
            _onCurrencyChange(currency, walletStore, receiveKey));

    reaction(
            (_) => store.depositCurrency,
            (CryptoCurrency currency) =>
            _onCurrencyChange(currency, walletStore, depositKey));

    reaction((_) => store.depositAmount, (String amount) {
      if (depositKey.currentState.amountController.text != amount) {
        depositKey.currentState.amountController.text = amount;
      }
    });

    reaction((_) => store.receiveAmount, (String amount) {
      if (receiveKey.currentState.amountController.text !=
          store.receiveAmount) {
        receiveKey.currentState.amountController.text = amount;
      }
    });

    reaction((_) => store.provider, (ExchangeProvider provider) {
      receiveKey.currentState.isAddressEditable(isEditable: true);
      receiveKey.currentState.isAmountEditable(isEditable: false);
      depositKey.currentState.isAddressEditable(isEditable: true);
      depositKey.currentState.isAmountEditable(isEditable: true);

      receiveKey.currentState.changeIsAmountEstimated(true);
    });

    reaction((_) => store.tradeState, (ExchangeTradeState state) {
      if (state is TradeIsCreatedFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
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

    reaction((_) => store.limitsState, (LimitsState state) {
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

    reaction((_) => walletStore.address, (String address) {
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