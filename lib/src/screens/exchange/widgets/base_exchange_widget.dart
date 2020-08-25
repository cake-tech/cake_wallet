import 'dart:ui';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_template.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/template_tile.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/src/stores/exchange/limits_state.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/exchange_card.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/top_panel.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';

class BaseExchangeWidget extends StatefulWidget {
  BaseExchangeWidget({
    @ required this.exchangeViewModel,
    this.isTemplate = false,
  });

  final ExchangeViewModel exchangeViewModel;
  final bool isTemplate;

  @override
  BaseExchangeWidgetState createState() =>
  BaseExchangeWidgetState(
    exchangeViewModel: exchangeViewModel,
    isTemplate: isTemplate
  );
}

class BaseExchangeWidgetState extends State<BaseExchangeWidget> {
  BaseExchangeWidgetState({
    @ required this.exchangeViewModel,
    @ required this.isTemplate,
  });

  final ExchangeViewModel exchangeViewModel;
  final bool isTemplate;

  final depositKey = GlobalKey<ExchangeCardState>();
  final receiveKey = GlobalKey<ExchangeCardState>();
  final _formKey = GlobalKey<FormState>();
  var _isReactionsSet = false;

  @override
  Widget build(BuildContext context) {
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

    WidgetsBinding.instance.addPostFrameCallback(
            (_) => _setReactions(context, exchangeViewModel));

    return Container(
      color: PaletteDark.backgroundColor,
      child: Form(
          key: _formKey,
          child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: Column(
              children: <Widget>[
                TopPanel(
                    color: PaletteDark.darkNightBlue,
                    edgeInsets: EdgeInsets.only(bottom: 32),
                    widget: Column(
                      children: <Widget>[
                        TopPanel(
                            edgeInsets: EdgeInsets.fromLTRB(24, 29, 24, 32),
                            color: PaletteDark.wildVioletBlue,
                            widget: Observer(
                              builder: (_) => ExchangeCard(
                                key: depositKey,
                                title: S.of(context).you_will_send,
                                initialCurrency: exchangeViewModel.depositCurrency,
                                initialWalletName: depositWalletName,
                                initialAddress:
                                exchangeViewModel.depositCurrency == exchangeViewModel.wallet.currency
                                    ? exchangeViewModel.wallet.address
                                    : exchangeViewModel.depositAddress,
                                initialIsAmountEditable: true,
                                initialIsAddressEditable: exchangeViewModel.isDepositAddressEnabled,
                                isAmountEstimated: false,
                                currencies: CryptoCurrency.all,
                                onCurrencySelected: (currency) =>
                                    exchangeViewModel.changeDepositCurrency(currency: currency),
                                imageArrow: arrowBottomPurple,
                                currencyButtonColor: PaletteDark.wildVioletBlue,
                                addressButtonsColor: PaletteDark.moderateBlue,
                                currencyValueValidator: AmountValidator(
                                    type: exchangeViewModel.wallet.type),
                                addressTextFieldValidator: AddressValidator(
                                    type: exchangeViewModel.depositCurrency),
                              ),
                            )
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 29, left: 24, right: 24),
                          child: Observer(
                              builder: (_) => ExchangeCard(
                                key: receiveKey,
                                title: S.of(context).you_will_get,
                                initialCurrency: exchangeViewModel.receiveCurrency,
                                initialWalletName: receiveWalletName,
                                initialAddress:
                                exchangeViewModel.receiveCurrency == exchangeViewModel.wallet.currency
                                    ? exchangeViewModel.wallet.address
                                    : exchangeViewModel.receiveAddress,
                                initialIsAmountEditable: false,
                                initialIsAddressEditable: exchangeViewModel.isReceiveAddressEnabled,
                                isAmountEstimated: true,
                                currencies: CryptoCurrency.all,
                                onCurrencySelected: (currency) => exchangeViewModel
                                    .changeReceiveCurrency(currency: currency),
                                imageArrow: arrowBottomCakeGreen,
                                currencyButtonColor: PaletteDark.darkNightBlue,
                                addressButtonsColor: PaletteDark.moderateBlue,
                                currencyValueValidator: AmountValidator(
                                    type: exchangeViewModel.wallet.type),
                                addressTextFieldValidator: AddressValidator(
                                    type: exchangeViewModel.receiveCurrency),
                              )),
                        )
                      ],
                    )
                ),
                isTemplate
                ? Offstage()
                : Padding(
                  padding: EdgeInsets.only(
                      top: 30,
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
                            color: PaletteDark.darkCyanBlue
                        ),
                      )
                    ],
                  ),
                ),
                isTemplate
                ? Offstage()
                : Container(
                  height: 40,
                  width: double.infinity,
                  padding: EdgeInsets.only(left: 24),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => Navigator.of(context)
                              .pushNamed(Routes.exchangeTemplate),
                          child: Container(
                            padding: EdgeInsets.only(left: 1, right: 10),
                            child: DottedBorder(
                                borderType: BorderType.RRect,
                                dashPattern: [6, 4],
                                color: PaletteDark.darkCyanBlue,
                                strokeWidth: 2,
                                radius: Radius.circular(20),
                                child: Container(
                                  height: 34,
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
                                        color: PaletteDark.darkCyanBlue
                                    ),
                                  ),
                                )
                            ),
                          ),
                        ),
                        Observer(
                            builder: (_) {
                              final templates = exchangeViewModel.templates;
                              final itemCount = exchangeViewModel.templates.length;

                              return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: itemCount,
                                  itemBuilder: (context, index) {
                                    final template = templates[index];

                                    return TemplateTile(
                                      key: UniqueKey(),
                                      amount: template.amount,
                                      from: template.depositCurrency,
                                      to: template.receiveCurrency,
                                      onTap: () {
                                        applyTemplate(exchangeViewModel, template);
                                      },
                                      onRemove: () {
                                        showDialog<void>(
                                            context: context,
                                            builder: (dialogContext) {
                                              return AlertWithTwoActions(
                                                  alertTitle: S.of(context).template,
                                                  alertContent: S.of(context).confirm_delete_template,
                                                  leftButtonText: S.of(context).delete,
                                                  rightButtonText: S.of(context).cancel,
                                                  actionLeftButton: () {
                                                    Navigator.of(dialogContext).pop();
                                                    exchangeViewModel.exchangeTemplateStore.remove(template: template);
                                                    exchangeViewModel.exchangeTemplateStore.update();
                                                  },
                                                  actionRightButton: () => Navigator.of(dialogContext).pop()
                                              );
                                            }
                                        );
                                      },
                                    );
                                  }
                              );
                            }
                        ),
                      ],
                    )
                  )
                )
              ],
            ),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
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
                      style: TextStyle(
                          color: PaletteDark.darkCyanBlue,
                          fontWeight: FontWeight.w500,
                          fontSize: 12
                      ),
                    ),
                  );
                }),
              ),
              isTemplate
              ? PrimaryButton(
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      exchangeViewModel.exchangeTemplateStore.addTemplate(
                          amount: exchangeViewModel.depositAmount,
                          depositCurrency: exchangeViewModel.depositCurrency.toString(),
                          receiveCurrency: exchangeViewModel.receiveCurrency.toString(),
                          provider: exchangeViewModel.provider.toString(),
                          depositAddress: exchangeViewModel.depositAddress,
                          receiveAddress: exchangeViewModel.receiveAddress
                      );
                      exchangeViewModel.exchangeTemplateStore.update();
                      Navigator.of(context).pop();
                    }
                  },
                  text: S.of(context).save,
                  color: Colors.green,
                  textColor: Colors.white
              )
              : Observer(
                  builder: (_) => LoadingPrimaryButton(
                    text: S.of(context).exchange,
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        exchangeViewModel.createTrade();
                      }
                    },
                    color: Colors.blue,
                    textColor: Colors.white,
                    isLoading: exchangeViewModel.tradeState is TradeIsCreating,
                  )),
            ]),
          )),
    );
  }

  void applyTemplate(ExchangeViewModel exchangeViewModel,
      ExchangeTemplate template) {
    exchangeViewModel.changeDepositCurrency(
        currency: CryptoCurrency.fromString(template.depositCurrency));
    exchangeViewModel.changeReceiveCurrency(
        currency: CryptoCurrency.fromString(template.receiveCurrency));

    switch (template.provider) {
      case 'XMR.TO':
        exchangeViewModel.changeProvider(
            provider: exchangeViewModel.providerList[0]);
        break;
      case 'ChangeNOW':
        exchangeViewModel.changeProvider(
            provider: exchangeViewModel.providerList[1]);
        break;
      case 'MorphToken':
        exchangeViewModel.changeProvider(
            provider: exchangeViewModel.providerList[2]);
        break;
    }

    exchangeViewModel.changeDepositAmount(amount: template.amount);
    exchangeViewModel.depositAddress = template.depositAddress;
    exchangeViewModel.receiveAddress = template.receiveAddress;
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

    _onCurrencyChange(exchangeViewModel.receiveCurrency, exchangeViewModel, receiveKey);
    _onCurrencyChange(exchangeViewModel.depositCurrency, exchangeViewModel, depositKey);

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

    reaction((_) => exchangeViewModel.isDepositAddressEnabled, (bool isEnabled) {
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

    reaction((_) => exchangeViewModel.isReceiveAddressEnabled, (bool isEnabled) {
      receiveKey.currentState.isAddressEditable(isEditable: isEnabled);
    });

    reaction((_) => exchangeViewModel.tradeState, (ExchangeTradeState state) {
      if (state is TradeIsCreatedFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).error,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop()
                );
              });
        });
      }
      if (state is TradeIsCreatedSuccessfully) {
        Navigator.of(context)
            .pushNamed(Routes.exchangeConfirm, arguments: state.trade);
      }
    });

    reaction((_) => exchangeViewModel.limitsState, (LimitsState state) {
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
            () => exchangeViewModel.depositAddress = depositAddressController.text);

    depositAmountController.addListener(() {
      if (depositAmountController.text != exchangeViewModel.depositAmount) {
        exchangeViewModel.changeDepositAmount(amount: depositAmountController.text);
      }
    });

    receiveAddressController.addListener(
            () => exchangeViewModel.receiveAddress = receiveAddressController.text);

    receiveAmountController.addListener(() {
      if (receiveAmountController.text != exchangeViewModel.receiveAmount) {
        exchangeViewModel.changeReceiveAmount(amount: receiveAmountController.text);
      }
    });

    reaction((_) => exchangeViewModel.wallet.address, (String address) {
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
      ExchangeViewModel exchangeViewModel,
      GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == exchangeViewModel.wallet.currency;

    key.currentState.changeSelectedCurrency(currency);
    key.currentState
        .changeWalletName(isCurrentTypeWallet
        ? exchangeViewModel.wallet.name : null);

    key.currentState
        .changeAddress(address: isCurrentTypeWallet
        ? exchangeViewModel.wallet.address : '');

    key.currentState.changeAmount(amount: '');
  }

  void _onWalletNameChange(ExchangeViewModel exchangeViewModel,
      CryptoCurrency currency,
      GlobalKey<ExchangeCardState> key) {
    final isCurrentTypeWallet = currency == exchangeViewModel.wallet.currency;

    if (isCurrentTypeWallet) {
      key.currentState.changeWalletName(exchangeViewModel.wallet.name);
      key.currentState.addressController.text = exchangeViewModel.wallet.address;
    } else if (key.currentState.addressController.text ==
        exchangeViewModel.wallet.address) {
      key.currentState.changeWalletName(null);
      key.currentState.addressController.text = null;
    }
  }
}