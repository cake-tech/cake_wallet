import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/exchange/provider/chainflip_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/fiat_amount_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_memo_input.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_syncing_indicator.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/provider_selector_page.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/refund_address_modal.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/swap_address_selection_modal.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/swap_confirm_sheet.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/swap_limit_popup.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/swap_options_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart';
import 'package:cake_wallet/src/screens/send/widgets/extract_address_from_parsed.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/debounce.dart';
import 'package:cake_wallet/utils/decimal_input_formatter.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cake_wallet/view_model/wallet_switcher_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currencies_with_memo.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class NewSwapPage extends StatefulWidget {
  NewSwapPage(this.exchangeViewModel, this.authService, this.initialPaymentRequest,
      {required this.walletSwitcherViewModel, CryptoCurrency? initialCurrency}) {
    depositWalletName = exchangeViewModel.depositCurrency == CryptoCurrency.xmr
        ? exchangeViewModel.wallet.name
        : null;
    receiveWalletName = exchangeViewModel.receiveCurrency == CryptoCurrency.xmr
        ? exchangeViewModel.wallet.name
        : null;
    if (initialCurrency != null) {
      exchangeViewModel.changeDepositCurrency(currency: initialCurrency);
    }
  }

  final ExchangeViewModel exchangeViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;
  final AuthService authService;
  final PaymentRequest? initialPaymentRequest;
  late final String? depositWalletName;
  late final String? receiveWalletName;

  @override
  State<NewSwapPage> createState() => _NewSwapPageState();
}

class _NewSwapPageState extends State<NewSwapPage> {
  final depositKey = GlobalKey<SwapAmountBoxState>();
  final receiveKey = GlobalKey<SwapAmountBoxState>();
  final formKey = GlobalKey<FormState>();
  final _depositAmountFocus = FocusNode();
  final _depositAddressFocus = FocusNode();
  final _receiveAmountFocus = FocusNode();
  final _receiveAddressFocus = FocusNode();
  final _receiveAmountDebounce = Debounce(Duration(milliseconds: 500));
  Debounce _depositAmountDebounce = Debounce(Duration(milliseconds: 500));

  bool get _shouldWaitTillSynced =>
      [CryptoCurrency.xmr, CryptoCurrency.btc, CryptoCurrency.ltc]
          .contains(widget.exchangeViewModel.depositCurrency) &&
      !(widget.exchangeViewModel.status is SyncedSyncStatus);

  @override
  void initState() {
    super.initState();
    if (widget.exchangeViewModel.feesViewModel.isLowFee) {
      _showFeeAlert(context);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // if (!widget.exchangeViewModel.decentralizedExchangesPromptDismissed) {
      //   showMaterialModalBottomSheet(
      //       context: context,
      //       backgroundColor: Colors.transparent,
      //       isDismissible: false,
      //       builder: (context) {
      //         return SwapProviderInitialPreferenceModal();
      //       }).then((val) {
      //     widget.exchangeViewModel.dismissDecentralizedExchangesPrompt();
      //     if (val is bool && val == true && !widget.exchangeViewModel.forceDecentralizedExchanges) {
      //       widget.exchangeViewModel.toggleForceDecentralizedExchanges();
      //     }
      //   });
      // }

      final depositAddressController = depositKey.currentState!.addressController;
      final depositAmountController = depositKey.currentState!.amountController;
      final receiveAddressController = receiveKey.currentState!.addressController;
      final receiveAmountController = receiveKey.currentState!.amountController;
      final depositFiatAmountController = depositKey.currentState!.fiatAmountController;
      final receiveFiatAmountController = receiveKey.currentState!.fiatAmountController;

      depositFiatAmountController.addListener(() {
        if (!depositKey.currentState!.amountFocusNode.hasFocus) {
          return;
        }
        widget.exchangeViewModel.isFixedRateMode = false;
        widget.exchangeViewModel.isSendAllEnabled = false;
        Future.delayed(Duration(milliseconds: 200)).then((_) {
          if (double.tryParse(depositFiatAmountController.text) != null) {
            widget.exchangeViewModel
                .setDepositAmountFromFiat(fiatAmount: depositFiatAmountController.text);
            receiveKey.currentState?.updateFiatAmount();
          }
        });
      });
      receiveFiatAmountController.addListener(() {
        if (!receiveKey.currentState!.amountFocusNode.hasFocus) return;

        widget.exchangeViewModel.enableFixedRateMode();
        widget.exchangeViewModel.isSendAllEnabled = false;
        Future.delayed(Duration(milliseconds: 200)).then((_) {
          if (double.tryParse(receiveFiatAmountController.text) != null) {
            String text = receiveFiatAmountController.text;
            if (text.contains(".")) {
              text = text.replaceAll(RegExp(r'0+$'), '');
              text = text.replaceAll(RegExp(r'\.$'), '');
            }
            widget.exchangeViewModel
                .setReceiveAmountFromFiat(fiatAmount: receiveFiatAmountController.text);
            depositKey.currentState!.updateFiatAmount();
          }
        });
      });
      reaction((_) => widget.exchangeViewModel.isFixedRateMode, (val) {
        Future.delayed(Duration(seconds: 3)).then((_) {
          if (val) {
            if (depositKey.currentState?.mounted == true)
              depositKey.currentState!.updateFiatAmount();
          } else {
            if (receiveKey.currentState?.mounted == true)
              receiveKey.currentState!.updateFiatAmount();
          }
        });
      });

      reaction((_) => widget.exchangeViewModel.depositAmount, (String amount) {
        if (depositKey.currentState!.amountFocusNode.hasFocus) return;

        if (widget.exchangeViewModel.isSendAllEnabled) {
          depositAmountController.text = S.of(context).all;
        } else if (depositAmountController.text != amount && amount != S.of(context).all) {
          depositAmountController.text = amount;
        }
      });

      _onCurrencyChange(
          widget.exchangeViewModel.receiveCurrency, widget.exchangeViewModel, receiveKey);
      _onCurrencyChange(
          widget.exchangeViewModel.depositCurrency, widget.exchangeViewModel, depositKey);

      reaction(
          (_) => widget.exchangeViewModel.wallet.name,
          (_) => _onWalletNameChange(
              widget.exchangeViewModel, widget.exchangeViewModel.receiveCurrency, receiveKey));

      reaction(
          (_) => widget.exchangeViewModel.wallet.name,
          (_) => _onWalletNameChange(
              widget.exchangeViewModel, widget.exchangeViewModel.depositCurrency, depositKey));

      reaction(
        (_) => widget.exchangeViewModel.receiveCurrency,
        (currency) => _onCurrencyChange(currency, widget.exchangeViewModel, receiveKey),
      );

      reaction(
        (_) => widget.exchangeViewModel.depositCurrency,
        (currency) => _onCurrencyChange(currency, widget.exchangeViewModel, depositKey),
      );

      reaction((_) => widget.exchangeViewModel.depositAddress, (String address) {
        if (depositKey.currentState!.addressController.text != address) {
          depositKey.currentState!.addressController.text = address;
        }
      });

      reaction((_) => widget.exchangeViewModel.isDepositAddressEnabled, (isEnabled) {});

      reaction((_) => widget.exchangeViewModel.receiveAmount, (String amount) {
        if (receiveKey.currentState!.amountController.text != amount) {
          receiveKey.currentState!.amountController.text = amount;
        }
      });

      reaction((_) => widget.exchangeViewModel.receiveAddress, (String address) {
        if (receiveKey.currentState!.addressController.text != address) {
          receiveKey.currentState!.addressController.text = address;
        }
      });

      reaction((_) => widget.exchangeViewModel.isReceiveAmountEditable,
          (bool isReceiveAmountEditable) {});

      reaction((_) => widget.exchangeViewModel.tradeState, (ExchangeTradeState state) {
        if (state is TradeIsCreatedFailure) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showPopUp<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertWithOneAction(
                        key: ValueKey('exchange_page_trade_creation_failure_dialog_key'),
                        buttonKey:
                            ValueKey('exchange_page_trade_creation_failure_dialog_button_key'),
                        alertTitle: S.of(context).provider_error(state.title),
                        alertContent: state.error,
                        buttonText: S.of(context).ok,
                        buttonAction: () => Navigator.of(context).pop());
                  });
            }
          });
        }
        if (state is TradeIsCreatedSuccessfully) {
          if (widget.exchangeViewModel.tradeStarted) return;
          final receiveAmount = widget.exchangeViewModel.receiveAmount;
          // FIXME we don't know why a reset is/was needed here, it messes up ui so i removed it
          // widget.exchangeViewModel.reset();
          // (widget.exchangeViewModel.tradesStore.trade?.provider ==
          //             ExchangeProviderDescription.thorChain ||
          //         widget.exchangeViewModel.tradesStore.trade?.provider ==
          //             ExchangeProviderDescription.chainflip)
          //     ? Navigator.of(context).pushReplacementNamed(Routes.exchangeTrade)
          //     : Navigator.of(context).pushReplacementNamed(Routes.exchangeConfirm);
          widget.exchangeViewModel.tradeStarted = true;
          final vm = getIt.get<ExchangeTradeViewModel>();
          final page = SwapConfirmSheet(
            exchangeViewModel: widget.exchangeViewModel,
            exchangeTradeViewModel: vm,
            receiveAmount: receiveAmount,
          );
          showMaterialModalBottomSheet(
              context: context, builder: (context) => page, backgroundColor: Colors.transparent);
        }
      });

      reaction((_) => widget.exchangeViewModel.bestRate, (double rate) {
        if (widget.exchangeViewModel.isFixedRateMode) {
          widget.exchangeViewModel.changeReceiveAmount(amount: receiveAmountController.text);
        } else {
          printV("bestrate");
          if (depositKey.currentState?._fiatInputMode?? false || depositAmountController.text.isEmpty || depositAmountController.text == S.current.all)
            widget.exchangeViewModel
                .changeDepositAmount(amount: widget.exchangeViewModel.depositAmount);
          else
            widget.exchangeViewModel.changeDepositAmount(amount: depositAmountController.text);
        }
      });

      depositAddressController.addListener(
          () => widget.exchangeViewModel.depositAddress = depositAddressController.text);

      depositAmountController.addListener(() {
        if (depositAmountController.text != widget.exchangeViewModel.depositAmount &&
            depositAmountController.text != S.of(context).all) {
          widget.exchangeViewModel.isSendAllEnabled = false;
          final isThorChain = widget.exchangeViewModel.selectedProviders
              .any((provider) => provider is ThorChainExchangeProvider);
          final isChainflip = widget.exchangeViewModel.selectedProviders
              .any((provider) => provider is ChainflipExchangeProvider);

          _depositAmountDebounce = isThorChain || isChainflip
              ? Debounce(Duration(milliseconds: 1000))
              : Debounce(Duration(milliseconds: 500));

          _depositAmountDebounce.run(() {
            widget.exchangeViewModel.calculateBestRate();
            if (depositAmountController.text != widget.exchangeViewModel.depositAmount &&
                depositAmountController.text != S.of(context).all) {
              widget.exchangeViewModel.changeDepositAmount(amount: depositAmountController.text);
            }
            widget.exchangeViewModel.isReceiveAmountEntered = false;
            widget.exchangeViewModel.isFixedRateMode = false;
            if (receiveKey.currentState != null &&
                !receiveKey.currentState!.amountFocusNode.hasFocus) {
              receiveKey.currentState!.updateFiatAmount();
            }
          });
        }
      });

      receiveAddressController.addListener(
          () => widget.exchangeViewModel.receiveAddress = receiveAddressController.text);

      receiveAmountController.addListener(() {
        if (receiveAmountController.text != widget.exchangeViewModel.receiveAmount) {
          _receiveAmountDebounce.run(() {
            widget.exchangeViewModel.calculateBestRate();
            widget.exchangeViewModel.changeReceiveAmount(amount: receiveAmountController.text);
            widget.exchangeViewModel.isReceiveAmountEntered = true;
            widget.exchangeViewModel.enableFixedRateMode();
            if (!depositKey.currentState!.amountFocusNode.hasFocus) {
              depositKey.currentState!.updateFiatAmount();
            }
          });
        }
      });

      reaction((_) => widget.exchangeViewModel.wallet.walletAddresses.addressForExchange,
          (String address) {
        if (widget.exchangeViewModel.depositCurrency == CryptoCurrency.xmr) {
          depositKey.currentState!.changeAddress(address: address);
        }

        // if (widget.exchangeViewModel.receiveCurrency == CryptoCurrency.xmr) {
        //   receiveKey.currentState!.changeAddress(address: address);
        // }
      });

      _depositAddressFocus.addListener(() async {
        if (!_depositAddressFocus.hasFocus && depositAddressController.text.isNotEmpty) {
          final domain = depositAddressController.text;
          widget.exchangeViewModel.depositAddress =
              await fetchParsedAddress(context, domain, widget.exchangeViewModel.depositCurrency);
        }
      });

      _receiveAddressFocus.addListener(() async {
        if (!_receiveAddressFocus.hasFocus && receiveAddressController.text.isNotEmpty) {
          final domain = receiveAddressController.text;
          widget.exchangeViewModel.receiveAddress =
              await fetchParsedAddress(context, domain, widget.exchangeViewModel.receiveCurrency);
        }
      });

      _receiveAmountFocus.addListener(() {
        if (_receiveAmountFocus.hasFocus) {
          widget.exchangeViewModel.enableFixedRateMode();
        }
        // exchangeViewModel.changeReceiveAmount(amount: receiveAmountController.text);
      });

      _depositAmountFocus.addListener(() {
        widget.exchangeViewModel.isFixedRateMode = false;
        // exchangeViewModel.changeDepositAmount(
        //   amount: depositAmountController.text);
      });

      if (widget.initialPaymentRequest != null) {
        try {
          widget.exchangeViewModel.receiveCurrency =
              CryptoCurrency.fromString(widget.initialPaymentRequest!.scheme);
          widget.exchangeViewModel.setCanonicalReceiveAmount(widget.initialPaymentRequest!.amount);
          widget.exchangeViewModel.receiveAddress = widget.initialPaymentRequest!.address;
        } catch (e) {
          printV('error: ${e.toString()}');
          // TODO
        }
      }
    });
  }

  @override
  void dispose() {
    _depositAmountFocus.dispose();
    _depositAddressFocus.dispose();
    _receiveAmountFocus.dispose();
    _receiveAddressFocus.dispose();
    widget.exchangeViewModel.dispose();
    super.dispose();
  }

  void _onCurrencyChange(CryptoCurrency currency, ExchangeViewModel exchangeViewModel,
      GlobalKey<SwapAmountBoxState> key) {
    final isCurrentTypeWallet = exchangeViewModel.useSameWalletAddress(currency);

    if (key == depositKey && !isCurrentTypeWallet) exchangeViewModel.isSendFromExternal = true;
    if (key == depositKey && isCurrentTypeWallet) exchangeViewModel.isSendFromExternal = false;

    if (key == depositKey) {
      key.currentState!.changeAddress(
        address:
            isCurrentTypeWallet ? exchangeViewModel.wallet.walletAddresses.addressForExchange : '',
      );
    }
  }

  void _onWalletNameChange(ExchangeViewModel exchangeViewModel, CryptoCurrency currency,
      GlobalKey<SwapAmountBoxState> key) {
    final isCurrentTypeWallet = exchangeViewModel.useSameWalletAddress(currency);

    if (isCurrentTypeWallet) {
      key.currentState!.addressController.text =
          exchangeViewModel.wallet.walletAddresses.addressForExchange;
    } else if (key.currentState!.addressController.text ==
        exchangeViewModel.wallet.walletAddresses.addressForExchange) {
      key.currentState!.addressController.text = '';
    }
  }

  Future<String> fetchParsedAddress(
      BuildContext context, String domain, CryptoCurrency currency) async {
    printV("$domain");
    final parsedAddress = await getIt.get<AddressResolver>().resolve(context, domain, currency);
    return extractAddressFromParsed(context, parsedAddress);
  }

  void _showFeeAlert(BuildContext context) async {
    await Future<void>.delayed(Duration(seconds: 1));
    if (!context.mounted) {
      return;
    }

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
    if (confirmed) {
      widget.exchangeViewModel.feesViewModel.setDefaultTransactionPriority();
    }
  }

  void disposeBestRateSync() => widget.exchangeViewModel.bestRateSync.cancel();

  @override
  Widget build(BuildContext context) {
    return KeyboardHideOverlay(
      unfocusOnTap: true,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).swap,
              leadingIcon: Icon(Icons.close),
              onLeadingPressed: Navigator.of(context).maybePop,
              trailingIcon: CakeImageWidget(imageUrl:
                "assets/new-ui/options.svg",
                colorFilter:
                    ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
              ),
              onTrailingPressed: () {
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) => Material(
                        child: SwapOptionsPage(exchangeViewModel: widget.exchangeViewModel))));
              },
            ),
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: RepaintBoundary(
                          child: Form(
                            key: formKey,
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              controller: ModalScrollController.of(context),
                              child: Column(
                                children: [
                                  Observer(
                                    builder: (_) => SwapAmountBox(
                                      isReceiverCard: false,
                                      walletSwitcherViewModel: widget.walletSwitcherViewModel,
                                      exchangeViewModel: widget.exchangeViewModel,
                                      onDispose: disposeBestRateSync,
                                      hasAllAmount: widget.exchangeViewModel.hasAllAmount,
                                      allAmount: widget.exchangeViewModel.hasAllAmount
                                          ? () => widget.exchangeViewModel.enableSendAllAmount()
                                          : null,
                                      key: depositKey,
                                      title: S.of(context).send,
                                      currency: widget.exchangeViewModel.depositCurrency,
                                      useBaseUnit: widget.exchangeViewModel.useDepositBaseUnit,
                                      hasRefundAddress: true,
                                      currencies: widget.exchangeViewModel.depositCurrencies,
                                      onCurrencySelected: (currency) {
                                        if (currency is CryptoCurrency) {
                                          widget.exchangeViewModel
                                              .changeDepositCurrency(currency: currency);
                                        }
                                      },
                                      currencyValueValidator: (value) {
                                        return !widget.exchangeViewModel.isFixedRateMode &&
                                                value != S.of(context).all
                                            ? AmountValidator(
                                                isAutovalidate: true,
                                                currency: widget.exchangeViewModel.isFixedRateMode
                                                    ? widget.exchangeViewModel.receiveCurrency
                                                    : widget.exchangeViewModel.depositCurrency,
                                                minValue:
                                                    widget.exchangeViewModel.limits.min.toString(),
                                                maxValue:
                                                    widget.exchangeViewModel.limits.max.toString(),
                                                amountParsingProxy:
                                                    widget.exchangeViewModel.amountParsingProxy,
                                              ).call(value)
                                            : null;
                                      },
                                      addressTextFieldValidator: AddressValidator(
                                          type: widget.exchangeViewModel.depositCurrency),
                                      onPushPasteButton: (context) async {
                                        final clipboard = await Clipboard.getData('text/plain');
                                        widget.exchangeViewModel.depositAddress = clipboard?.text ?? '';

                                        final domain = widget.exchangeViewModel.depositAddress;
                                        widget.exchangeViewModel.depositAddress =
                                            await fetchParsedAddress(context, domain,
                                                widget.exchangeViewModel.depositCurrency);
                                      },
                                      onPushAddressBookButton: (context) async {
                                        final domain = widget.exchangeViewModel.depositAddress;
                                        widget.exchangeViewModel.depositAddress =
                                            await fetchParsedAddress(context, domain,
                                                widget.exchangeViewModel.depositCurrency);
                                      },
                                    ),
                                  ),
                                  SwapLimitPopup(exchangeViewModel: widget.exchangeViewModel),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          height: 1,
                                          width: double.infinity,
                                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                        ),
                                        ModernButton.svg(
                                          size: 36,
                                          iconSize: 24,
                                          svgPath: "assets/new-ui/swap_amounts.svg",
                                          onPressed: widget.exchangeViewModel.reverseSwapDirection,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Observer(
                                    builder: (_) => SwapAmountBox(
                                      isReceiverCard: true,
                                      walletSwitcherViewModel: widget.walletSwitcherViewModel,
                                      exchangeViewModel: widget.exchangeViewModel,
                                      onDispose: disposeBestRateSync,
                                      key: receiveKey,
                                      title: S.of(context).receive,
                                      currencies: widget.exchangeViewModel.receiveCurrencies,
                                      currency: widget.exchangeViewModel.receiveCurrency,
                                      useBaseUnit: widget.exchangeViewModel.useReceiveBaseUnit,
                                      onCurrencySelected: (currency) {
                                        if (currency is CryptoCurrency) {
                                          widget.exchangeViewModel
                                              .changeReceiveCurrency(currency: currency);
                                        }
                                      },
                                      currencyValueValidator: (value) {
                                        return widget.exchangeViewModel.isFixedRateMode
                                            ? AmountValidator(
                                                isAutovalidate: true,
                                                currency: widget.exchangeViewModel.receiveCurrency,
                                                minValue: widget.exchangeViewModel.limits.min.toString(),
                                                maxValue: widget.exchangeViewModel.limits.max.toString(),
                                                amountParsingProxy:
                                                    widget.exchangeViewModel.amountParsingProxy,
                                              ).call(value)
                                            : null;
                                      },
                                      addressTextFieldValidator: AddressValidator(
                                          type: widget.exchangeViewModel.receiveCurrency),
                                      onPushPasteButton: (context) async {
                                        final clipboard = await Clipboard.getData('text/plain');
                                        widget.exchangeViewModel.receiveAddress = clipboard?.text ?? '';

                                        final domain = widget.exchangeViewModel.receiveAddress;
                                        widget.exchangeViewModel.receiveAddress =
                                            await fetchParsedAddress(context, domain,
                                                widget.exchangeViewModel.receiveCurrency);
                                      },
                                      onPushAddressBookButton: (context) async {
                                        final domain = widget.exchangeViewModel.receiveAddress;
                                        widget.exchangeViewModel.receiveAddress =
                                            await fetchParsedAddress(context, domain,
                                                widget.exchangeViewModel.receiveCurrency);
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Observer(
                        builder: (_) => Column(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (widget.exchangeViewModel.status is! SyncedSyncStatus)
                              SendSyncingIndicator(status: widget.exchangeViewModel.status),
                            if (widget.exchangeViewModel.isFixedRateMode)
                              Text(S.of(context).exchange_rate_is_fixed,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 12)),
                            SwapProviderPreview(exchangeViewModel: widget.exchangeViewModel),
                            Observer(
                              builder: (_) => LoadingPrimaryButton(
                                key: ValueKey('exchange_page_exchange_button_key'),
                                text: widget.exchangeViewModel.isAvailableInSelected
                                    ? S.of(context).swap
                                    : S.of(context).change_selected_exchanges,
                                onPressed: widget.exchangeViewModel.isAvailableInSelected
                                    ? () {
                                        FocusScope.of(context).unfocus();
                                        if (formKey.currentState != null &&
                                            formKey.currentState!.validate()) {
                                          if (_shouldWaitTillSynced) {
                                            showPopUp<void>(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertWithOneAction(
                                                  alertTitle: S.of(context).exchange,
                                                  alertContent:
                                                      S.of(context).exchange_sync_alert_content,
                                                  buttonText: S.of(context).ok,
                                                  buttonAction: () => Navigator.of(context).pop(),
                                                );
                                              },
                                            );
                                          } else {
                                            final check =
                                                widget.exchangeViewModel.shouldDisplayTOTP();
                                            widget.authService.authenticateAction(
                                              context,
                                              conditionToDetermineIfToUse2FA: check,
                                              onAuthSuccess: (value) {
                                                if (value) {
                                                  widget.exchangeViewModel.createTrade();
                                                }
                                              },
                                            );
                                          }
                                        }
                                      }
                                    : () => PresentProviderPicker(
                                            exchangeViewModel: widget.exchangeViewModel)
                                        .presentProviderPicker(context),
                                color: Theme.of(context).colorScheme.primary,
                                textColor: Theme.of(context).colorScheme.onPrimary,
                                isDisabled: _swapButtonDisabled(),
                                isLoading: widget.exchangeViewModel.tradeState is TradeIsCreating,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  bool _swapButtonDisabled() {
    if (widget.exchangeViewModel.selectedProviders.isEmpty) return true;

    if (widget.exchangeViewModel.receiveAddress.isEmpty) return true;

    if (widget.exchangeViewModel.status is! SyncedSyncStatus) return true;

    if (widget.exchangeViewModel.depositAmount.isEmpty) return true;

    return false;
  }
}

class SwapProviderPreview extends StatelessWidget {
  const SwapProviderPreview({super.key, required this.exchangeViewModel});

  final ExchangeViewModel exchangeViewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      if (exchangeViewModel.depositAmount.isEmpty) return SizedBox.shrink();

      final provider = exchangeViewModel.forcedProvider ?? exchangeViewModel.providerDisplay;
      final rate = exchangeViewModel.forcedProvider == null
          ? exchangeViewModel.bestRate
          : exchangeViewModel.forcedProviderRate;

      return GestureDetector(
        onTap: () {
          if (provider != null) {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (context) => Material(
                child: ProviderSelectorPage(exchangeViewModel: exchangeViewModel),
              ),
            ));
          }
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    if (provider != null)
                      CakeImageWidget(imageUrl: provider.description.image, width: 28, height: 28),
                    if (provider == null) CupertinoActivityIndicator(),
                    Text(
                      provider?.title ?? "${S.of(context).finding_provider}...",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: provider == null
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface),
                    )
                  ],
                ),
                if (provider != null)
                  Row(
                    children: [
                      Text(
                        "1 ${exchangeViewModel.depositCurrency} ≈ ${rate.toStringAsFixed(6)} ${exchangeViewModel.receiveCurrency}",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      CakeImageWidget(imageUrl:
                        "assets/new-ui/chooser.svg",
                        colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
                      )
                    ],
                  )
              ],
            ),
          ),
        ),
      );
    });
  }
}

class SwapAmountBox extends StatefulWidget {
  SwapAmountBox({
    Key? key,
    required this.currency,
    required this.currencies,
    required this.onCurrencySelected,
    this.currencyValueValidator,
    this.addressTextFieldValidator,
    this.title = '',
    this.hasRefundAddress = false,
    this.hasAllAmount = false,
    this.useBaseUnit = false,
    this.allAmount,
    this.onPushPasteButton,
    this.onPushAddressBookButton,
    this.onDispose,
    required this.exchangeViewModel,
    required this.isReceiverCard,
    required this.walletSwitcherViewModel,
  }) : super(key: key);

  final List<Currency> currencies;
  final Function(Currency) onCurrencySelected;
  final String title;
  final bool isReceiverCard;
  final Currency currency;
  final bool useBaseUnit;
  final bool hasRefundAddress;
  final FormFieldValidator<String>? currencyValueValidator;
  final FormFieldValidator<String>? addressTextFieldValidator;
  final FormFieldValidator<String> allAmountValidator = AllAmountValidator();
  final bool hasAllAmount;
  final VoidCallback? allAmount;
  final void Function(BuildContext context)? onPushPasteButton;
  final void Function(BuildContext context)? onPushAddressBookButton;
  final Function()? onDispose;
  final ExchangeViewModel exchangeViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;

  @override
  State<SwapAmountBox> createState() => SwapAmountBoxState();
}

class SwapAmountBoxState extends State<SwapAmountBox> {
  final addressController = TextEditingController();
  final amountController = TextEditingController();
  final fiatAmountController = TextEditingController();
  final amountFocusNode = FocusNode();
  final memoController = TextEditingController();
  ReactionDisposer? _memoReactionDisposer;
  VoidCallback? _memoListener;

  @override
  void initState() {
    if (widget.isReceiverCard) {
      memoController.text = widget.exchangeViewModel.receiveAddressExtraId;

      _memoListener = () {
        if (widget.exchangeViewModel.receiveAddressExtraId != memoController.text) {
          widget.exchangeViewModel.receiveAddressExtraId = memoController.text;
        }
      };
      memoController.addListener(_memoListener!);

      _memoReactionDisposer =
          reaction((_) => widget.exchangeViewModel.receiveAddressExtraId, (String value) {
        if (memoController.text != value) {
          memoController.text = value;
        }
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    if (_memoListener != null) {
      memoController.removeListener(_memoListener!);
    }
    _memoReactionDisposer?.call();
    memoController.dispose();
    super.dispose();
  }

  bool _fiatInputMode = false;

  @override
  Widget build(BuildContext context) {
    final currencyToShow = (widget.currency is CryptoCurrency)
        ? widget.exchangeViewModel.amountParsingProxy
            .getCryptoSymbol(widget.currency as CryptoCurrency)
        : widget.currency.name.toUpperCase();

    final chainIconPath = (widget.currency is CryptoCurrency)
        ? _getCurrencyChainIconPath(widget.currency as CryptoCurrency)
        : null;

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Container(
          decoration: ShapeDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(24))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 12,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: amountFocusNode.requestFocus,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 4,
                    children: [
                      Expanded(
                        child: Row(
                          spacing: 4,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: IntrinsicWidth(
                                child: TextFormField(
                                  keyboardType: TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: !widget.useBaseUnit,
                                  ),
                                  validator: _fiatInputMode ? null : widget.currencyValueValidator,
                                  controller:
                                      _fiatInputMode ? fiatAmountController : amountController,
                                  focusNode: amountFocusNode,
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                    hintText: "0",
                                    fillColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                  ),
                                  inputFormatters: <TextInputFormatter>[
                                    DecimalInputFormatter(
                                      maxDecimals:
                                          widget.useBaseUnit ? 0 : widget.currency.decimals,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_fiatInputMode)
                              Center(
                                child: Text(
                                  widget.exchangeViewModel.fiat.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _presentCurrencyPicker,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(999999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0, bottom: 4, left: 4, right: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CakeImageWidget(
                                  imageUrl: widget.currency.iconPath ?? "",
                                  width: 28,
                                  height: 28,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  currencyToShow,
                                  textAlign: TextAlign.center,
                                ),
                                if (chainIconPath != null && chainIconPath.isNotEmpty) ...[
                                  SizedBox(width: 4),
                                  CakeImageWidget(
                                    imageUrl: chainIconPath,
                                    width: 12,
                                    height: 12,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).colorScheme.onSurfaceVariant,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6)
                                ] else
                                  const SizedBox(width: 10),
                                Container(
                                  width:16,height:16,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9999999999),
                                    color: Theme.of(context).colorScheme.surfaceContainerHigh
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: RotatedBox(
                                      quarterTurns: 2,
                                      child: CakeImageWidget(
                                        imageUrl: "assets/new-ui/dropdown_arrow.svg",
                                        width: 4,
                                        height: 4,
                                        colorFilter: ColorFilter.mode(
                                          Theme.of(context).colorScheme.primary,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Observer(
                  builder: (_) {
                    final hasAllAmount = !(widget.isReceiverCard ||
                        widget.exchangeViewModel.isSendFromExternal ||
                        !widget.exchangeViewModel.hasAllAmount);

                    return FiatAmountBar(
                      foregroundElementColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      allAmountColor: hasAllAmount ? null : Colors.transparent,
                      allAmountTextColor:
                          hasAllAmount ? null : Theme.of(context).colorScheme.onSurfaceVariant,
                      fiatInputMode: _fiatInputMode,
                      allAmount: !hasAllAmount
                          ? widget.isReceiverCard
                              ? null
                              : widget.exchangeViewModel.balanceDisplay
                          : widget.exchangeViewModel.depositAvailableAmount,
                      onSwitchButtonPressed: () {
                        setState(() => _fiatInputMode = !_fiatInputMode);
                        if (_fiatInputMode) {
                          updateFiatAmount();
                        } else {
                          amountController.text = widget.exchangeViewModel.depositAmount;
                        }
                      },
                      onAllButtonPressed: (){
                        setState(() {
                          _fiatInputMode = false;
                        });
                        widget.allAmount?.call();
                      },
                      cryptoAmount: widget.isReceiverCard
                          ? widget.exchangeViewModel.roundedReceiveAmount(6)
                          : widget.exchangeViewModel.roundedDepositAmount(6),
                      fiatAmount: widget.isReceiverCard
                          ? widget.exchangeViewModel.roundedReceiveAmountFiat(6)
                          : widget.exchangeViewModel.roundedDepositAmountFiat(6),
                      cryptoCurrencySymbol: currencyToShow,
                      fiatCurrencySymbol: widget.exchangeViewModel.fiat.symbol,
                    );
                  },
                ),
                Observer(
                  builder: (_) {
                    final addressEmpty = (widget.isReceiverCard &&
                            widget.exchangeViewModel.receiveAddress.isEmpty) ||
                        (!widget.isReceiverCard && widget.exchangeViewModel.depositAddress.isEmpty);
                    final addressPickerText = widget.isReceiverCard
                        ? (addressEmpty ? S.of(context).select_receiver : S.of(context).to)
                        : S.of(context).from;
                    final addressDescription = widget.isReceiverCard
                        ? widget.exchangeViewModel.receiveAddressDisplayName ??
                            _middleTruncate(widget.exchangeViewModel.receiveAddress, 8, 8)
                        : widget.exchangeViewModel.isSendFromExternal
                            ? S.of(context).external
                            : widget.exchangeViewModel.wallet.name;
                    return Row(
                      spacing: 8,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: _presentWalletPicker,
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                  color: (addressEmpty && widget.isReceiverCard)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(9999)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Observer(
                                  builder: (_) => Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        spacing: 8,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Text(
                                            addressPickerText,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: (addressEmpty && widget.isReceiverCard)
                                                    ? Theme.of(context).colorScheme.onPrimary
                                                    : Theme.of(context).colorScheme.onSurface),
                                          ),
                                          Text(
                                            addressDescription,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context).colorScheme.primary),
                                          )
                                        ],
                                      ),
                                      RotatedBox(
                                        quarterTurns: 2,
                                        child: CakeImageWidget(
                                          imageUrl: "assets/new-ui/dropdown_arrow.svg",
                                          colorFilter: ColorFilter.mode(
                                            (addressEmpty && widget.isReceiverCard)
                                                ? Theme.of(context).colorScheme.onPrimary
                                                : Theme.of(context).colorScheme.onSurface,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!widget.isReceiverCard &&
                            widget.exchangeViewModel.isSendFromExternal &&
                            widget.exchangeViewModel.depositAddress.isEmpty)
                          ModernButton.svg(
                            svgPath: "assets/new-ui/refund_address.svg",
                            onPressed: askForRefundAddress,
                            size: 36,
                            iconSize: 18,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        if (widget.isReceiverCard &&
                            widget.exchangeViewModel.receiveAddress.isEmpty) ...[
                          ModernButton.svg(
                            svgPath: "assets/new-ui/paste.svg",
                            onPressed: () => widget.onPushPasteButton?.call(context),
                            size: 36,
                            iconSize: 20,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          ModernButton.svg(
                            svgPath: "assets/new-ui/scan.svg",
                            onPressed: () => _presentQRScanner(context),
                            size: 36,
                            iconSize: 20,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        ]
                      ],
                    );
                  },
                ),
                if (widget.isReceiverCard)
                  Observer(builder: (_) {
                    final selected = widget.exchangeViewModel.receiveCurrency;
                    final labelType = memoLabelTypeFor(selected);
                    if (labelType == null) return const SizedBox.shrink();

                    final isDestinationTag = labelType == MemoLabelType.destinationTag;
                    final hint = isDestinationTag
                        ? S.of(context).destination_tag_optional
                        : S.of(context).memo_optional;
                    final disclaimer = isDestinationTag
                        ? S.of(context).destination_tag_swap_disclaimer
                        : S.of(context).memo_swap_disclaimer;

                    return NewSendMemoInput(
                      memoController: memoController,
                      maxMemoLength: isDestinationTag ? 20 : 256,
                      memoLength: memoController.text.length,
                      hintText: hint,
                      disclaimerText: disclaimer,
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void changeAddress({required String address}) {
    setState(() => addressController.text = _normalizeAddressFormat(address));
  }

  void changeAmount({required String amount}) {
    setState(() => amountController.text = amount);
  }

  String _normalizeAddressFormat(String address) {
    if (address.startsWith('bitcoincash:')) address = address.substring(12);
    return address;
  }

  void _presentCurrencyPicker() {
    final rawCurrencies = widget.isReceiverCard
        ? widget.exchangeViewModel.receiveCurrencies
        : widget.exchangeViewModel.depositCurrencies;
    final currencies = rawCurrencies.whereType<CryptoCurrency>().toList();
    appendEvmDefaultTokens(currencies);
    if (widget.exchangeViewModel.wallet.type == WalletType.bitcoin) {
      currencies.sort((a, b) {
        if (a == CryptoCurrency.btcln) return -1;
        if (b == CryptoCurrency.btcln) return 1;
        return 0;
      });
    }

    final selected = widget.isReceiverCard
        ? widget.exchangeViewModel.receiveCurrency
        : widget.exchangeViewModel.depositCurrency;

    CurrencyPickerSheet.show(
      context: context,
      args: CurrencyPickerArgs(
        items: currencies,
        selected: selected,
        recentsSource: RecentsSource.trades,
        onSelected: widget.onCurrencySelected,
        symbolResolver: widget.exchangeViewModel.amountParsingProxy.getCryptoSymbol,
      ),
    );
  }

  Future<void> _presentQRScanner(BuildContext context) async {
    bool isCameraPermissionGranted =
        await PermissionHandler.checkPermission(Permission.camera, context);
    if (!isCameraPermissionGranted) return;
    final code = await presentQRScanner(context);
    if (code == null) return;
    if (code.isEmpty) return;

    try {
      final uri = Uri.parse(code);
      widget.exchangeViewModel.receiveAddress = uri.path;
    } catch (_) {}
  }

  void _presentWalletPicker() async {
    final res = await showMaterialModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SwapAddressSelectionModal(
              isSelectingReceiver: widget.isReceiverCard,
              exchangeViewModel: widget.exchangeViewModel,
            ),
          );
        });
    if (res != null && res is SwapAddressSelectionResult) {
      if (widget.isReceiverCard) {
        widget.exchangeViewModel.selectedAddressBookWallet = res.walletInfo;
        widget.exchangeViewModel.receiveAddress = res.address!;
        if (res.walletInfo?.name != null) {
          if (res.accountName != null) {
            widget.exchangeViewModel.receiveAddressDisplayName =
                "${res.walletInfo!.name} → ${res.accountName}";
          } else {
            widget.exchangeViewModel.receiveAddressDisplayName = res.walletInfo!.name;
          }
        }
      } else if (res.address == null || res.address!.isEmpty) {
        widget.exchangeViewModel.isSendFromExternal = true;
        askForRefundAddress();
      } else {
        widget.exchangeViewModel.isSendFromExternal = false;
        switchToDepositWallet(res.walletInfo!.name);
      }
    }
  }

  void switchToDepositWallet(String walletName) async {
    final walletType = cryptoCurrencyOrTokenToWalletType(widget.exchangeViewModel.depositCurrency);
    if (walletType == null) return;
    final wallet = await WalletInfo.get(walletName, walletType);
    if (wallet == null) return;
    widget.exchangeViewModel.depositAddress = wallet.address;
    addressController.text = _normalizeAddressFormat(wallet.address);
    widget.walletSwitcherViewModel.selectWallet(wallet);
    await widget.walletSwitcherViewModel.switchToSelectedWallet();
  }

  void askForRefundAddress() async {
    final refundAddress = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RefundAddressModal(
              selectedCurrency: widget.exchangeViewModel.depositCurrency,
              isFromWalletSelection: true,
            ));
    if (refundAddress != null && refundAddress is String) {
      widget.exchangeViewModel.depositAddress = refundAddress;
    } else {
      widget.exchangeViewModel.depositAddress = "";
    }
  }

  void updateFiatAmount() {
    final newText = widget.isReceiverCard
        ? widget.exchangeViewModel.receiveAmountFiat
        : widget.exchangeViewModel.depositAmountFiat;

    if (double.tryParse(fiatAmountController.text) != double.tryParse(newText)) {
      if (newText == "0.00") {
        fiatAmountController.text = "";
      } else {
        fiatAmountController.text =
            newText.replaceAll(RegExp(r'(?<=\.\d*)0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    }
  }

  String _middleTruncate(String s, int head, int tail) {
    if (s.length <= head + tail + 3) return s;
    return s.substring(0, head) + '...' + s.substring(s.length - tail);
  }

  String? _getCurrencyChainIconPath(CryptoCurrency curr) {
    try {
      if (curr.chainIconPath != null) return curr.chainIconPath!;

      if (curr.tag != null) {
        final currencyFromTag = CryptoCurrency.fromString(curr.tag!);

        if (currencyFromTag.chainIconPath != null) return currencyFromTag.chainIconPath!;
      }
    } catch (_) {}
    return null;
  }
}
