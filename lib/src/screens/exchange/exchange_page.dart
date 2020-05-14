import 'dart:ui';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_template.dart';
import 'package:cake_wallet/src/widgets/template_tile.dart';
import 'package:dotted_border/dotted_border.dart';
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

class ExchangePage extends BasePage {
  @override
  String get title => S.current.exchange;

  @override
  Color get backgroundColor => PaletteDark.walletCardSubAddressField;

  final Image arrowBottom =
      Image.asset('assets/images/arrow_bottom_purple_icon.png', color: Colors.white, height: 6);

  @override
  Widget middle(BuildContext context) {
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

  @override
  Widget trailing(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);

    return ButtonTheme(
      minWidth: double.minPositive,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: FlatButton(
          padding: EdgeInsets.all(0),
          child: Text(
            S.of(context).clear,
            style: TextStyle(
                color: PaletteDark.walletCardText,
                fontWeight: FontWeight.w500,
                fontSize: 14),
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
    final images = List<Image>();

    for (ExchangeProvider provider in items) {
      switch (provider.description) {
        case ExchangeProviderDescription.xmrto:
          images.add(Image.asset('assets/images/xmr_btc.png'));
          break;
        case ExchangeProviderDescription.changeNow:
          images.add(Image.asset('assets/images/change_now.png'));
          break;
        case ExchangeProviderDescription.morphToken:
          images.add(Image.asset('assets/images/morph_icon.png'));
          break;
      }
    }

    showDialog<void>(
        builder: (_) => ProviderPicker(
            items: items,
            images: images,
            selectedAtIndex: selectedItem,
            title: S.of(context).change_exchange_provider,
            onItemSelected: (ExchangeProvider provider) =>
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
                                    : exchangeStore.depositAddress,
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
                                    : exchangeStore.receiveAddress,
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
                Padding(
                  padding: EdgeInsets.only(
                      top: 32,
                      left: 24,
                      bottom: 24
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        S.of(context).send_templates,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: PaletteDark.walletCardText
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: double.infinity,
                  padding: EdgeInsets.only(left: 24),
                  child: Observer(
                      builder: (_) {
                        final itemCount = exchangeTemplateStore.templates.length + 1;

                        return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: itemCount,
                            itemBuilder: (context, index) {

                              if (index == 0) {
                                return GestureDetector(
                                  onTap: () => Navigator.of(context)
                                      .pushNamed(Routes.exchangeTemplate),
                                  child: Container(
                                    padding: EdgeInsets.only(right: 10),
                                    child: DottedBorder(
                                        borderType: BorderType.RRect,
                                        dashPattern: [8, 4],
                                        color: PaletteDark.menuList,
                                        strokeWidth: 2,
                                        radius: Radius.circular(20),
                                        child: Container(
                                          height: 40,
                                          width: 75,
                                          padding: EdgeInsets.only(left: 10, right: 10),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(Radius.circular(20)),
                                            color: Colors.transparent,
                                          ),
                                          child: Text(
                                            S.of(context).send_new,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: PaletteDark.walletCardText
                                            ),
                                          ),
                                        )
                                    ),
                                  ),
                                );
                              }

                              index -= 1;

                              final template = exchangeTemplateStore.templates[index];

                              return TemplateTile(
                                  amount: template.amount,
                                  from: template.depositCurrency,
                                  to: template.receiveCurrency,
                                  onTap: () {
                                    applyTemplate(exchangeStore, template);
                                  }
                              );
                            }
                        );
                      }
                  ),
                )
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
              Observer(
                  builder: (_) => LoadingPrimaryButton(
                    text: S.of(context).exchange,
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        exchangeStore.createTrade();
                      }
                    },
                    color: Colors.blue,
                    textColor: Colors.white,
                    isLoading: exchangeStore.tradeState is TradeIsCreating,
                  )),
            ]),
          )),
    );
  }

  void applyTemplate(ExchangeStore store, ExchangeTemplate template) {
    store.changeDepositCurrency(currency: CryptoCurrency.fromString(template.depositCurrency));
    store.changeReceiveCurrency(currency: CryptoCurrency.fromString(template.receiveCurrency));

    switch (template.provider) {
      case 'XMR.TO':
        store.changeProvider(provider: store.providerList[0]);
        break;
      case 'ChangeNOW':
        store.changeProvider(provider: store.providerList[1]);
        break;
      case 'MorphToken':
        store.changeProvider(provider: store.providerList[2]);
        break;
    }

    store.changeDepositAmount(amount: template.amount);
    store.depositAddress = template.depositAddress;
    store.receiveAddress = template.receiveAddress;
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

    reaction((_) => store.depositAddress, (String address) {
      if (depositKey.currentState.addressController.text != address) {
        depositKey.currentState.addressController.text = address;
      }
    });

    reaction((_) => store.receiveAmount, (String amount) {
      if (receiveKey.currentState.amountController.text !=
          store.receiveAmount) {
        receiveKey.currentState.amountController.text = amount;
      }
    });

    reaction((_) => store.receiveAddress, (String address) {
      if (receiveKey.currentState.addressController.text != address) {
        receiveKey.currentState.addressController.text = address;
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
