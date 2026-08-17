import "package:cake_wallet/core/address_resolver/address_resolver_service.dart";
import "package:cake_wallet/core/address_validator.dart";
import "package:cake_wallet/core/amount_validator.dart";
import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/exchange/exchange_trade_state.dart";
import "package:cake_wallet/exchange/provider/chainflip_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_syncing_indicator.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/anypay_swap_footer.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/provider_selector_page.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_amount_box.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_confirm_sheet.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_from_send_args.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_limit_popup.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_options_page.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_section_header.dart";
import "package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/utils/debounce.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart";
import "package:cake_wallet/view_model/exchange/exchange_view_model.dart";
import "package:cake_wallet/view_model/wallet_switcher_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class NewSwapPage extends StatefulWidget {
  NewSwapPage(
    this.exchangeViewModel,
    this.authService,
    this.adrResService,
    this.initialPaymentRequest, {
    required this.walletSwitcherViewModel,
    CryptoCurrency? initialCurrency,
    this.fromSend,
  }) {
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
  final AddressResolverService adrResService;
  final PaymentRequest? initialPaymentRequest;
  final SwapFromSendArgs? fromSend;
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
  final _receiveAmountDebounce = Debounce(const Duration(milliseconds: 500));
  Debounce _depositAmountDebounce = Debounce(const Duration(milliseconds: 500));
  final List<ReactionDisposer> _disposers = [];

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
      if (!mounted) {
        return;
      }

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
        Future.delayed(const Duration(milliseconds: 200)).then((_) {
          if (!mounted) {
            return;
          }
          if (double.tryParse(depositFiatAmountController.text) != null) {
            widget.exchangeViewModel
                .setDepositAmountFromFiat(fiatAmount: depositFiatAmountController.text);
            receiveKey.currentState?.updateFiatAmount();
          }
        });
      });
      receiveFiatAmountController.addListener(() {
        if (!receiveKey.currentState!.amountFocusNode.hasFocus) {
          return;
        }

        widget.exchangeViewModel.enableFixedRateMode();
        widget.exchangeViewModel.isSendAllEnabled = false;
        Future.delayed(const Duration(milliseconds: 200)).then((_) {
          if (!mounted) {
            return;
          }
          if (double.tryParse(receiveFiatAmountController.text) != null) {
            String text = receiveFiatAmountController.text;
            if (text.contains(".")) {
              text = text.replaceAll(RegExp(r"0+$"), "");
              text = text.replaceAll(RegExp(r"\.$"), "");
            }
            widget.exchangeViewModel
                .setReceiveAmountFromFiat(fiatAmount: receiveFiatAmountController.text);
            depositKey.currentState!.updateFiatAmount();
          }
        });
      });
      _disposers.add(reaction((_) => widget.exchangeViewModel.isFixedRateMode, (val) {
        Future.delayed(const Duration(seconds: 3)).then((_) {
          if (val) {
            if (depositKey.currentState?.mounted == true) {
              depositKey.currentState!.updateFiatAmount();
            }
          } else {
            if (receiveKey.currentState?.mounted == true) {
              receiveKey.currentState!.updateFiatAmount();
            }
          }
        });
      }));

      _disposers.add(reaction((_) => widget.exchangeViewModel.depositAmount, (String amount) {
        if (depositKey.currentState!.amountFocusNode.hasFocus) {
          return;
        }

        if (widget.exchangeViewModel.isSendAllEnabled) {
          depositAmountController.text = S.of(context).all;
        } else if (depositAmountController.text != amount && amount != S.of(context).all) {
          depositAmountController.text = amount;
        }
      }));

      _onCurrencyChange(
        widget.exchangeViewModel.receiveCurrency,
        widget.exchangeViewModel,
        receiveKey,
      );
      _onCurrencyChange(
        widget.exchangeViewModel.depositCurrency,
        widget.exchangeViewModel,
        depositKey,
      );

      _disposers.add(reaction(
        (_) => widget.exchangeViewModel.wallet.name,
        (_) => _onWalletNameChange(
          widget.exchangeViewModel,
          widget.exchangeViewModel.receiveCurrency,
          receiveKey,
        ),
      ));

      _disposers.add(reaction(
        (_) => widget.exchangeViewModel.wallet.name,
        (_) => _onWalletNameChange(
          widget.exchangeViewModel,
          widget.exchangeViewModel.depositCurrency,
          depositKey,
        ),
      ));

      _disposers.add(reaction(
        (_) => widget.exchangeViewModel.receiveCurrency,
        (currency) => _onCurrencyChange(currency, widget.exchangeViewModel, receiveKey),
      ));

      _disposers.add(reaction(
        (_) => widget.exchangeViewModel.depositCurrency,
        (currency) => _onCurrencyChange(currency, widget.exchangeViewModel, depositKey),
      ));

      _disposers.add(reaction((_) => widget.exchangeViewModel.depositAddress, (String address) {
        if (depositKey.currentState!.addressController.text != address) {
          depositKey.currentState!.addressController.text = address;
        }
      }));

      _disposers
          .add(reaction((_) => widget.exchangeViewModel.isDepositAddressEnabled, (isEnabled) {}));

      _disposers.add(reaction((_) => widget.exchangeViewModel.receiveAmount, (String amount) {
        if (receiveKey.currentState!.amountController.text != amount) {
          receiveKey.currentState!.amountController.text = amount;
        }
      }));

      _disposers.add(reaction((_) => widget.exchangeViewModel.receiveAddress, (String address) {
        if (receiveKey.currentState!.addressController.text != address) {
          receiveKey.currentState!.addressController.text = address;
        }
      }));

      _disposers.add(reaction(
        (_) => widget.exchangeViewModel.isReceiveAmountEditable,
        (bool isReceiveAmountEditable) {},
      ));

      _disposers
          .add(reaction((_) => widget.exchangeViewModel.tradeState, (ExchangeTradeState state) {
        if (state is TradeIsCreatedFailure) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showPopUp<void>(
                context: context,
                builder: (BuildContext context) => AlertWithOneAction(
                  key: const ValueKey("exchange_page_trade_creation_failure_dialog_key"),
                  buttonKey:
                      const ValueKey("exchange_page_trade_creation_failure_dialog_button_key"),
                  alertTitle: S.of(context).provider_error(state.title),
                  alertContent: state.error,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop(),
                ),
              );
            }
          });
        }
        if (state is TradeIsCreatedSuccessfully) {
          if (widget.exchangeViewModel.tradeStarted) {
            return;
          }
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
            context: context,
            builder: (context) => page,
            backgroundColor: Colors.transparent,
          );
        }
      }));

      _disposers.add(reaction((_) => widget.exchangeViewModel.bestRate, (double rate) {
        if (widget.exchangeViewModel.isFixedRateMode) {
          widget.exchangeViewModel.changeReceiveAmount(amount: receiveAmountController.text);
        } else {
          printV("bestrate");
          if ((depositKey.currentState?.fiatInputMode ?? false) ||
              depositAmountController.text.isEmpty ||
              depositAmountController.text == S.current.all) {
            widget.exchangeViewModel
                .changeDepositAmount(amount: widget.exchangeViewModel.depositAmount);
          } else {
            widget.exchangeViewModel.changeDepositAmount(amount: depositAmountController.text);
          }
        }
      }));

      _disposers.add(reaction((_) => widget.exchangeViewModel.forcedProviderRate, (double rate) {
        if (widget.exchangeViewModel.forcedProvider != null && rate == 0) {
          return;
        }
        if (widget.exchangeViewModel.isFixedRateMode) {
          widget.exchangeViewModel.changeReceiveAmount(amount: receiveAmountController.text);
        } else if (depositAmountController.text.isNotEmpty &&
            depositAmountController.text != S.current.all) {
          widget.exchangeViewModel.changeDepositAmount(amount: depositAmountController.text);
        }
      }));

      depositAddressController.addListener(
        () => widget.exchangeViewModel.depositAddress = depositAddressController.text,
      );

      depositAmountController.addListener(() {
        if (depositAmountController.text != widget.exchangeViewModel.depositAmount &&
            depositAmountController.text != S.of(context).all) {
          widget.exchangeViewModel.isSendAllEnabled = false;
          final isThorChain = widget.exchangeViewModel.selectedProviders
              .any((provider) => provider is ThorChainExchangeProvider);
          final isChainflip = widget.exchangeViewModel.selectedProviders
              .any((provider) => provider is ChainflipExchangeProvider);

          _depositAmountDebounce = isThorChain || isChainflip
              ? Debounce(const Duration(milliseconds: 1000))
              : Debounce(const Duration(milliseconds: 500));

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
        () => widget.exchangeViewModel.receiveAddress = receiveAddressController.text,
      );

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

      _disposers.add(
          reaction((_) => widget.exchangeViewModel.wallet.walletAddresses.addressForExchange,
              (String address) {
        if (widget.exchangeViewModel.depositCurrency == CryptoCurrency.xmr) {
          depositKey.currentState!.changeAddress(address: address);
        }

        // if (widget.exchangeViewModel.receiveCurrency == CryptoCurrency.xmr) {
        //   receiveKey.currentState!.changeAddress(address: address);
        // }
      }));

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
          printV("error: ${e.toString()}");
          // TODO
        }
      }

      if (widget.fromSend != null) {
        widget.exchangeViewModel.changeReceiveCurrency(currency: widget.fromSend!.receiveCurrency);
        widget.exchangeViewModel.receiveAddress = widget.fromSend!.recipientAddress;
        widget.exchangeViewModel.depositAddress =
            widget.exchangeViewModel.wallet.walletAddresses.addressForExchange;
        widget.exchangeViewModel.enableFixedRateMode();
        final receiveAmount = widget.fromSend!.receiveAmount;
        if (receiveAmount != null) {
          widget.exchangeViewModel.setCanonicalReceiveAmount(receiveAmount.toString());
        }
        widget.exchangeViewModel.calculateBestRate();
      }
    });
  }

  @override
  void dispose() {
    for (final disposer in _disposers) {
      disposer();
    }
    _receiveAmountDebounce.cancel();
    _depositAmountDebounce.cancel();
    _depositAmountFocus.dispose();
    _depositAddressFocus.dispose();
    _receiveAmountFocus.dispose();
    _receiveAddressFocus.dispose();
    widget.exchangeViewModel.dispose();
    super.dispose();
  }

  void _onCurrencyChange(
    CryptoCurrency currency,
    ExchangeViewModel exchangeViewModel,
    GlobalKey<SwapAmountBoxState> key,
  ) {
    final isCurrentTypeWallet = exchangeViewModel.useSameWalletAddress(currency);

    if (key == depositKey && !isCurrentTypeWallet) {
      exchangeViewModel.isSendFromExternal = true;
    }
    if (key == depositKey && isCurrentTypeWallet) {
      exchangeViewModel.isSendFromExternal = false;
    }

    if (key == depositKey) {
      key.currentState!.changeAddress(
        address:
            isCurrentTypeWallet ? exchangeViewModel.wallet.walletAddresses.addressForExchange : "",
      );
    }
  }

  void _onWalletNameChange(
    ExchangeViewModel exchangeViewModel,
    CryptoCurrency currency,
    GlobalKey<SwapAmountBoxState> key,
  ) {
    final isCurrentTypeWallet = exchangeViewModel.useSameWalletAddress(currency);

    if (isCurrentTypeWallet) {
      key.currentState!.addressController.text =
          exchangeViewModel.wallet.walletAddresses.addressForExchange;
    } else if (key.currentState!.addressController.text ==
        exchangeViewModel.wallet.walletAddresses.addressForExchange) {
      key.currentState!.addressController.text = "";
    }
  }

  Future<String> fetchParsedAddress(
    BuildContext context,
    String domain,
    CryptoCurrency currency,
  ) async {
    printV("$domain");
    final parsedAddress = await widget.adrResService
        .resolve(query: domain, wallet: widget.exchangeViewModel.wallet, currency: currency);
    return parsedAddress.isNotEmpty
        ? (parsedAddress.first.parsedAddressByCurrencyMap[currency] ?? domain)
        : domain;
  }

  void _showFeeAlert(BuildContext context) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!context.mounted) {
      return;
    }

    final confirmed = await showPopUp<bool>(
          context: context,
          builder: (dialogContext) => AlertWithTwoActions(
            alertTitle: S.of(context).low_fee,
            alertContent: S.of(context).low_fee_alert,
            leftButtonText: S.of(context).ignor,
            rightButtonText: S.of(context).use_suggested,
            actionLeftButton: () => Navigator.of(dialogContext).pop(false),
            actionRightButton: () => Navigator.of(dialogContext).pop(true),
          ),
        ) ??
        false;
    if (confirmed) {
      widget.exchangeViewModel.feesViewModel.setDefaultTransactionPriority();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final fromSend = widget.fromSend;
    final fromType = widget.exchangeViewModel.wallet.type;
    final fromName = walletTypeToString(fromType);
    final fromIcon = symbolIconPathForWalletType(fromType) ?? "";

    final targetType = fromSend?.targetWalletType;
    final toName = targetType != null ? walletTypeToString(targetType) : "";
    final toIcon = (targetType != null ? symbolIconPathForWalletType(targetType) : null) ?? "";

    return KeyboardHideOverlay(
      unfocusOnTap: true,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            ModalTopBar(
              title:
                  fromSend != null ? S.of(context).swap_from_network(fromName) : S.of(context).swap,
              leadingIcon: Icon(fromSend != null ? Icons.arrow_back_ios_new : Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: Navigator.of(context).maybePop,
              trailingIcon: fromSend != null
                  ? null
                  : CakeImageWidget(
                      imageUrl: "assets/new-ui/options.svg",
                      colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
                    ),
              trailingSemanticLabel: S.of(context).configure,
              onTrailingPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => Material(
                      child: SwapOptionsPage(exchangeViewModel: widget.exchangeViewModel),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
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
                                  if (fromSend != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: SwapSectionHeader(
                                        label: S.of(context).from,
                                        networkName: fromName,
                                        networkIconPath: fromIcon,
                                      ),
                                    ),
                                  Observer(
                                    builder: (_) => SwapAmountBox(
                                      isReceiverCard: false,
                                      walletSwitcherViewModel: widget.walletSwitcherViewModel,
                                      exchangeViewModel: widget.exchangeViewModel,
                                      hasAllAmount: widget.exchangeViewModel.hasAllAmount,
                                      allAmount: widget.exchangeViewModel.hasAllAmount
                                          ? () => widget.exchangeViewModel.enableSendAllAmount()
                                          : null,
                                      key: depositKey,
                                      title: fromSend != null ? "" : S.of(context).send,
                                      sourceSelectorMode: fromSend != null,
                                      walletName: fromSend != null
                                          ? widget.exchangeViewModel.wallet.name
                                          : null,
                                      balanceByAsset: fromSend?.depositBalanceByAsset,
                                      useSingleNetworkLayout: fromSend != null,
                                      filteredNetwork: fromSend != null
                                          ? widget.exchangeViewModel.wallet.type
                                          : null,
                                      currency: widget.exchangeViewModel.depositCurrency,
                                      useBaseUnit: widget.exchangeViewModel.useDepositBaseUnit,
                                      hasRefundAddress: true,
                                      currencies: widget.exchangeViewModel.depositCurrencies,
                                      onCurrencySelected: (currency) {
                                        if (currency is! CryptoCurrency) {
                                          return;
                                        }
                                        final vm = widget.exchangeViewModel;
                                        if (fromSend == null) {
                                          vm.changeDepositCurrency(currency: currency);
                                          return;
                                        }
                                        final keepReceive = vm.receiveAmount;
                                        vm.changeDepositCurrency(currency: currency);
                                        vm.enableFixedRateMode();
                                        if (keepReceive.isNotEmpty) {
                                          vm.changeReceiveAmount(amount: keepReceive);
                                        } else {
                                          vm.calculateBestRate();
                                        }
                                      },
                                      currencyValueValidator: (value) => !widget
                                                  .exchangeViewModel.isFixedRateMode &&
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
                                          : null,
                                      addressTextFieldValidator: AddressValidator(
                                        type: widget.exchangeViewModel.depositCurrency,
                                      ),
                                      onPushPasteButton: (context) async {
                                        final clipboard = await Clipboard.getData("text/plain");
                                        widget.exchangeViewModel.depositAddress =
                                            clipboard?.text ?? "";

                                        final domain = widget.exchangeViewModel.depositAddress;
                                        widget.exchangeViewModel.depositAddress =
                                            await fetchParsedAddress(
                                          context,
                                          domain,
                                          widget.exchangeViewModel.depositCurrency,
                                        );
                                      },
                                      onPushAddressBookButton: (context) async {
                                        final domain = widget.exchangeViewModel.depositAddress;
                                        widget.exchangeViewModel.depositAddress =
                                            await fetchParsedAddress(
                                          context,
                                          domain,
                                          widget.exchangeViewModel.depositCurrency,
                                        );
                                      },
                                    ),
                                  ),
                                  SwapLimitPopup(exchangeViewModel: widget.exchangeViewModel),
                                  if (fromSend != null)
                                    Column(
                                      children: [
                                        const SizedBox(height: 24),
                                        Icon(
                                          Icons.arrow_downward,
                                          size: 24,
                                          color: colorScheme.onSurfaceVariant,
                                          semanticLabel: S.of(context).swap_reverse_direction,
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            height: 1,
                                            width: double.infinity,
                                            color: colorScheme.surfaceContainerHigh,
                                          ),
                                          ModernButton.svg(
                                            size: 36,
                                            iconSize: 24,
                                            svgPath: "assets/new-ui/swap_amounts.svg",
                                            onPressed:
                                                widget.exchangeViewModel.reverseSwapDirection,
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (fromSend != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: SwapSectionHeader(
                                        label: S.of(context).to,
                                        networkName: toName,
                                        networkIconPath: toIcon,
                                      ),
                                    ),
                                  Observer(
                                    builder: (_) => SwapAmountBox(
                                      isReceiverCard: true,
                                      walletSwitcherViewModel: widget.walletSwitcherViewModel,
                                      exchangeViewModel: widget.exchangeViewModel,
                                      key: receiveKey,
                                      title: fromSend != null ? "" : S.of(context).receive,
                                      filteredNetwork:
                                          fromSend != null ? fromSend.targetWalletType : null,
                                      currencies: widget.exchangeViewModel.receiveCurrencies,
                                      currency: widget.exchangeViewModel.receiveCurrency,
                                      useBaseUnit: widget.exchangeViewModel.useReceiveBaseUnit,
                                      onCurrencySelected: (currency) {
                                        if (currency is! CryptoCurrency) {
                                          return;
                                        }
                                        final vm = widget.exchangeViewModel;
                                        final keepAddress = vm.receiveAddress;
                                        vm.changeReceiveCurrency(currency: currency);
                                        if (fromSend != null) {
                                          if (keepAddress.isNotEmpty) {
                                            vm.receiveAddress = keepAddress;
                                          }
                                          vm.enableFixedRateMode();
                                          vm.calculateBestRate();
                                        }
                                      },
                                      currencyValueValidator: (value) => widget
                                              .exchangeViewModel.isFixedRateMode
                                          ? AmountValidator(
                                              isAutovalidate: true,
                                              currency: widget.exchangeViewModel.receiveCurrency,
                                              minValue:
                                                  widget.exchangeViewModel.limits.min.toString(),
                                              maxValue:
                                                  widget.exchangeViewModel.limits.max.toString(),
                                              amountParsingProxy:
                                                  widget.exchangeViewModel.amountParsingProxy,
                                            ).call(value)
                                          : null,
                                      addressTextFieldValidator: AddressValidator(
                                        type: widget.exchangeViewModel.receiveCurrency,
                                      ),
                                      onPushPasteButton: (context) async {
                                        final clipboard = await Clipboard.getData("text/plain");
                                        widget.exchangeViewModel.receiveAddress =
                                            clipboard?.text ?? "";

                                        final domain = widget.exchangeViewModel.receiveAddress;
                                        widget.exchangeViewModel.receiveAddress =
                                            await fetchParsedAddress(
                                          context,
                                          domain,
                                          widget.exchangeViewModel.receiveCurrency,
                                        );
                                      },
                                      onPushAddressBookButton: (context) async {
                                        final domain = widget.exchangeViewModel.receiveAddress;
                                        widget.exchangeViewModel.receiveAddress =
                                            await fetchParsedAddress(
                                          context,
                                          domain,
                                          widget.exchangeViewModel.receiveCurrency,
                                        );
                                      },
                                    ),
                                  ),
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
                            if (fromSend == null && widget.exchangeViewModel.isFixedRateMode)
                              Text(
                                S.of(context).exchange_rate_is_fixed,
                                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                              ),
                            if (fromSend != null)
                              AnyPaySwapFooter(exchangeViewModel: widget.exchangeViewModel)
                            else
                              SwapProviderPreview(exchangeViewModel: widget.exchangeViewModel),
                            Observer(
                              builder: (_) => LoadingPrimaryButton(
                                key: const ValueKey("exchange_page_exchange_button_key"),
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
                                              builder: (BuildContext context) => AlertWithOneAction(
                                                alertTitle: S.of(context).exchange,
                                                alertContent:
                                                    S.of(context).exchange_sync_alert_content,
                                                buttonText: S.of(context).ok,
                                                buttonAction: () => Navigator.of(context).pop(),
                                              ),
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
                                          exchangeViewModel: widget.exchangeViewModel,
                                        ).presentProviderPicker(context),
                                color: colorScheme.primary,
                                textColor: colorScheme.onPrimary,
                                isDisabled: _swapButtonDisabled(),
                                isLoading: widget.exchangeViewModel.tradeState is TradeIsCreating,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _swapButtonDisabled() {
    if (widget.exchangeViewModel.selectedProviders.isEmpty) {
      return true;
    }

    if (widget.exchangeViewModel.receiveAddress.isEmpty) {
      return true;
    }

    if (widget.exchangeViewModel.status is! SyncedSyncStatus) {
      return true;
    }

    if (widget.exchangeViewModel.depositAmount.isEmpty) {
      return true;
    }

    return false;
  }
}

class SwapProviderPreview extends StatelessWidget {
  const SwapProviderPreview({
    required this.exchangeViewModel,
    super.key,
  });

  final ExchangeViewModel exchangeViewModel;

  @override
  Widget build(BuildContext context) => Observer(
        builder: (_) {
          final isFetchingDeposit =
              exchangeViewModel.isFixedRateMode && exchangeViewModel.receiveAmount.isNotEmpty;
          if (exchangeViewModel.depositAmount.isEmpty && !isFetchingDeposit) {
            return const SizedBox.shrink();
          }

          final provider = exchangeViewModel.forcedProvider ?? exchangeViewModel.providerDisplay;
          final rate = exchangeViewModel.forcedProvider == null
              ? exchangeViewModel.bestRate
              : exchangeViewModel.forcedProviderRate;

          return GestureDetector(
            onTap: () {
              if (provider != null) {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => Material(
                      child: ProviderSelectorPage(exchangeViewModel: exchangeViewModel),
                    ),
                  ),
                );
              }
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 12,
                      children: [
                        if (provider != null)
                          CakeImageWidget(
                            imageUrl: provider.description.image,
                            width: 28,
                            height: 28,
                          ),
                        if (provider == null) const CupertinoActivityIndicator(),
                        Text(
                          provider?.title ?? "${S.of(context).finding_provider}...",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: provider == null
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
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
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          CakeImageWidget(
                            imageUrl: "assets/new-ui/chooser.svg",
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.onSurfaceVariant,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
