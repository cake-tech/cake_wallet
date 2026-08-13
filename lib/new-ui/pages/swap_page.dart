import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/address_resolver/address_resolver_service.dart";
import "package:cake_wallet/core/address_resolver/parsed_address.dart";
import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/entities/qr_scanner.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_presentation_event.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/rates/rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/fiat_amount_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_memo_input.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/provider_selector_page.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/refund_address_modal.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_address_selection_modal.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_confirm_sheet.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_limit_popup.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_options_page.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/decimal_input_formatter.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cake_wallet/utils/permission_handler.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:permission_handler/permission_handler.dart";

class NewSwapPage extends StatefulWidget {
  NewSwapPage(
    this.bloc,
    this.authService,
    this.adrResService,
    this.initialPaymentRequest, {
    CryptoCurrency? initialCurrency,
  }) {
    if (initialCurrency != null) {
      bloc.add(DepositCurrencyChanged(initialCurrency));
    }
  }

  final SwapBloc bloc;
  final AuthService authService;
  final AddressResolverService adrResService;
  final PaymentRequest? initialPaymentRequest;

  @override
  State<NewSwapPage> createState() => _NewSwapPageState();
}

class _NewSwapPageState extends State<NewSwapPage> {
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // if (widget.exchangeViewModel.feesViewModel.isLowFee) {
    //   _showFeeAlert(context);
    // }

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

      if (widget.initialPaymentRequest != null) {
        // try {
        final newCurr = CryptoCurrency.fromString(widget.initialPaymentRequest!.scheme);
        widget.bloc.add(DepositCurrencyChanged(newCurr));
        widget.bloc.add(
          DepositAmountChanged(Money.parse(widget.initialPaymentRequest!.amount, newCurr)),
        );
        widget.bloc.add(
          PayoutAddressChanged(ExternalSwapAddress(widget.initialPaymentRequest!.address)),
        );
        // } catch (e) {
        //   printV("error: ${e.toString()}");
        //   // TODO
        // }
      }
    });
  }

  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  // void _showFeeAlert(BuildContext context) async {
  //   await Future<void>.delayed(Duration(seconds: 1));
  //   if (!context.mounted) {
  //     return;
  //   }
  //
  //   final confirmed = await showPopUp<bool>(
  //           context: context,
  //           builder: (dialogContext) => AlertWithTwoActions(
  //                 alertTitle: S.of(context).low_fee,
  //                 alertContent: S.of(context).low_fee_alert,
  //                 leftButtonText: S.of(context).ignor,
  //                 rightButtonText: S.of(context).use_suggested,
  //                 actionLeftButton: () => Navigator.of(dialogContext).pop(false),
  //                 actionRightButton: () => Navigator.of(dialogContext).pop(true))) ??
  //       false;
  //   if (confirmed) {
  //     widget.exchangeViewModel.feesViewModel.setDefaultTransactionPriority();
  //   }
  // }

  @override
  Widget build(BuildContext context) => KeyboardHideOverlay(
    unfocusOnTap: true,
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: BlocPresentationListener<SwapBloc, SwapPresentationEvent>(
        bloc: widget.bloc,
        listener: (context, event) => switch (event) {
          AddressValidationFailed() => _showAddressValidationFailurePopup(),
          AliaspayAddressFound(:final address) => _showParsedAddressPopup(address),
          SwapCreationStarted() => _showConfirmSheet(),
          SwapAllNotReady() => _showSwapAllNotReadyPopup(),
        },
        child: BlocBuilder<SwapBloc, SwapState>(
          bloc: widget.bloc,
          builder: (context, state) => Column(
            children: [
              ModalTopBar(
                title: S.of(context).swap,
                leadingIcon: const Icon(Icons.close),
                leadingSemanticLabel: S.of(context).close,
                trailingSemanticLabel: S.of(context).configure,
                onLeadingPressed: Navigator.of(context).maybePop,
                trailingIcon: CakeImageWidget(
                  imageUrl: "assets/new-ui/options.svg",
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                onTrailingPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => Material(child: SwapOptionsPage(bloc: widget.bloc)),
                    ),
                  );
                },
              ),
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
                                    SwapAmountBox(isReceiverCard: false, bloc: widget.bloc),
                                    SwapLimitPopup(bloc: widget.bloc),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            height: 1,
                                            width: double.infinity,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surfaceContainerHigh,
                                          ),
                                          ModernButton.svg(
                                            size: 36,
                                            iconSize: 24,
                                            svgPath: "assets/new-ui/swap_amounts.svg",
                                            semanticLabel: S.of(context).swap_reverse_direction,
                                            onPressed: () =>
                                                widget.bloc.add(SwapDirectionReversed()),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SwapAmountBox(isReceiverCard: true, bloc: widget.bloc),
                                    const SizedBox(height: 24),
                                    SwapMemoInput(bloc: widget.bloc),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // if (widget.wallet.status is! SyncedSyncStatus)
                            //   SendSyncingIndicator(status: widget.exchangeViewModel.status),
                            if (widget.bloc.state is SwapStateWithInputs &&
                                (widget.bloc.state as SwapStateWithInputs).isFixedRate)
                              Text(
                                S.of(context).exchange_rate_is_fixed,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            SwapProviderPreview(bloc: widget.bloc),
                            BlocBuilder<RateCubit, RateState>(
                              bloc: widget.bloc.rateCubit,
                              builder: (context, rateState) => NewPrimaryButton(
                                text: S.of(context).swap,
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  if (formKey.currentState != null &&
                                      formKey.currentState!.validate()) {
                                    widget.authService.authenticateAction(
                                      context,
                                      conditionToDetermineIfToUse2FA: false,
                                      onAuthSuccess: (value) {
                                        if (value) {
                                          widget.bloc.add(SwapInitiated());
                                        }
                                      },
                                    );
                                  }
                                },
                                color: Theme.of(context).colorScheme.primary,
                                textColor: Theme.of(context).colorScheme.onPrimary,
                                disabled: !state.canInitiateSwap || rateState is! RatesLoaded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _showConfirmSheet() async {
    final page = SwapConfirmSheet(bloc: widget.bloc);
    await showMaterialModalBottomSheet(
      context: context,
      enableDrag: false,
      isDismissible: false,
      builder: (context) => page,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _showAddressValidationFailurePopup() async {
    if (widget.bloc.state case final SwapStateWithInputs s) {
      await showPopUp(
        context: context,
        builder: (context) => AlertWithOneAction(
          alertTitle: S.of(context).invalid_address,
          alertContent:
              "${S.of(context).invalid_address_desc} ${s.payoutAmount.currency.fullName ?? s.payoutAmount.currency.symbol}.",
          buttonText: S.of(context).ok,
          buttonAction: Navigator.of(context).pop,
        ),
      );
    }
  }

  Future<void> _showSwapAllNotReadyPopup() async {
    if (widget.bloc.state case final SwapStateWithInputs s) {
      await showPopUp(
        context: context,
        builder: (context) => AlertWithOneAction(
          alertTitle: S.of(context).syncing_wallet_alert_title,
          alertContent: S.of(context).sync_before_swap_all,
          buttonText: S.of(context).ok,
          buttonAction: Navigator.of(context).pop,
        ),
      );
    }
  }

  Future<void> _showParsedAddressPopup(ParsedAddress address) async {
    await showPopUp<bool>(
      context: context,
      builder: (context) => AlertWithOneAction(
        alertTitle: S.of(context).address_detected,
        headerTitleText: address.profileName.isEmpty ? null : address.profileName,
        headerImageProfileUrl: address.profileImageUrl.isEmpty
            ? address.addressSource.iconPath
            : address.profileImageUrl,
        alertContent: S
            .of(context)
            .extracted_address_content("${address.handle} (${address.addressSource.label})"),
        buttonText: S.of(context).ok,
        buttonAction: Navigator.of(context).pop,
      ),
    );
  }
}

class SwapMemoInput extends StatefulWidget {
  const SwapMemoInput({required this.bloc, super.key});

  final SwapBloc bloc;

  @override
  State<SwapMemoInput> createState() => _SwapMemoInputState();
}

class _SwapMemoInputState extends State<SwapMemoInput> {
  final memoController = TextEditingController();

  @override
  Widget build(BuildContext context) => BlocBuilder<SwapBloc, SwapState>(
    bloc: widget.bloc,
    builder: (context, state) {
      if (state case final SwapStateWithInputs s) {
        final labelType = s.payoutAmount.currency.memoLabelType;
        if (labelType == null) {
          return const SizedBox.shrink();
        }

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
      }
      return const SizedBox.shrink();
    },
  );
}

class SwapProviderPreview extends StatelessWidget {
  const SwapProviderPreview({required this.bloc, super.key});

  final SwapBloc bloc;

  @override
  Widget build(BuildContext context) => BlocBuilder<RateCubit, RateState>(
    bloc: bloc.rateCubit,
    builder: (context, rateState) => BlocBuilder<SwapBloc, SwapState>(
      bloc: bloc,
      builder: (context, state) {
        if (rateState is RatesNotLoaded) {
          return const SizedBox.shrink();
        }

        ProviderRate? rate;
        if (rateState case final RatesLoaded rs) {
          rate = rs.rates.max;
        }

        ExchangeProviderDescription? forcedProvider;
        if (state is SwapInputState && rateState is RatesNotFound) {
          forcedProvider = state.forcedProvider;
        }

        return GestureDetector(
          onTap: () {
            if (forcedProvider != null) {
              bloc.add(const ForcedProviderSelected(null));
              return;
            }
            if (rate != null) {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => Material(child: ProviderSelectorPage(bloc: bloc)),
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
                  if (rateState is RatesNotFound)
                    Flexible(
                      child: Row(
                        crossAxisAlignment: .center,
                        spacing: 12,
                        children: [
                          CakeImageWidget(
                            imageUrl: forcedProvider?.image ?? "assets/new-ui/warning.svg",
                            width: 28,
                            height: 28,
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: .start,
                              mainAxisAlignment: .center,
                              children: [
                                Text(
                                  forcedProvider == null
                                      ? S.of(context).no_rates_found
                                      : S.of(context).no_rate_from_provider(forcedProvider.title),
                                ),
                                Wrap(
                                  children: [
                                    Text(
                                      forcedProvider == null
                                          ? S.of(context).no_rates_found_desc
                                          : S.of(context).no_rate_from_provider_desc,
                                      style: TextStyle(fontSize: 12, color: Theme
                                          .of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    spacing: 12,
                    children: [
                      if (rate != null)
                        CakeImageWidget(imageUrl: rate.provider.image, width: 28, height: 28),
                      if (rateState is RatesLoading) const CupertinoActivityIndicator(),
                      if ([RatesLoading, RatesLoaded].contains(rateState.runtimeType))
                        Text(
                          rate?.provider.title ?? "${S.of(context).finding_provider}...",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: rate == null
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                  if (rate != null)
                    Row(
                      spacing: 4,
                      children: [
                        Text(
                          "1 ${rate.rate.base.symbol} ≈ ${rate.rate.quote.toStringWithPrecision(fractionalDigits: 6)} ${rate.rate.quote.currency.symbol}",
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
    ),
  );
}

class SwapAmountBox extends StatefulWidget {
  SwapAmountBox({required this.isReceiverCard, required this.bloc})
    : title = isReceiverCard ? S.current.receive : S.current.send;

  final String title;
  final bool isReceiverCard;
  final SwapBloc bloc;

  @override
  State<SwapAmountBox> createState() => SwapAmountBoxState();
}

class SwapAmountBoxState extends State<SwapAmountBox> {
  final amountController = TextEditingController();
  final fiatAmountController = TextEditingController();
  final amountFocusNode = FocusNode();

  bool _fiatInputMode = false;

  @override
  Widget build(BuildContext context) => BlocConsumer<SwapBloc, SwapState>(
    listener: (context, state) {
      if (state is SwapStateWithInputs) {
        final amount = widget.isReceiverCard ? state.payoutAmount : state.depositAmount;

        final changed = _fiatInputMode
            ? amount.fiatAmount.toDouble() != double.tryParse(fiatAmountController.text)
            : amount.cryptoAmount.toDouble() != double.tryParse(amountController.text);

        if (changed) {
          amountController.text = amount.cryptoAmount.isZero ? "" : amount.cryptoAmount.toString();
          fiatAmountController.text = amount.fiatAmount.isZero ? "" : amount.fiatAmount.toString();
        }
      }
    },
    bloc: widget.bloc,
    builder: (context, state) {
      final CryptoCurrency currency;
      final bool addressEmpty;
      final String addressDescription;
      final String addressPickerText;
      final String cryptoAmount;
      final bool hasSwapAll;
      final String fiatAmount;
      final Currency inputCurrency;
      if (state is SwapStateWithInputs) {
        currency = widget.isReceiverCard
            ? state.payoutAmount.currency
            : state.depositAmount.currency;
        addressEmpty = state.payoutAddress == null;
        addressDescription = widget.isReceiverCard
            ? state.payoutAddress?.displayName ?? ""
            : state.source.displayName;
        hasSwapAll = state is SwapInputState ? state.hasSwapAll : false;
        addressPickerText = widget.isReceiverCard
            ? (addressEmpty ? S.of(context).select_receiver : S.of(context).to)
            : S.of(context).from;
        cryptoAmount = widget.isReceiverCard
            ? state.payoutAmount.cryptoAmount.toStringWithPrecision(fractionalDigits: 6)
            : state.depositAmount.cryptoAmount.toStringWithPrecision(fractionalDigits: 6);
        fiatAmount = widget.isReceiverCard
            ? state.payoutAmount.fiatAmount.toStringWithPrecision(fractionalDigits: 2)
            : state.depositAmount.fiatAmount.toStringWithPrecision(fractionalDigits: 2);
      } else {
        currency = widget.bloc.spendingBalance.currency as CryptoCurrency;
        addressEmpty = false;
        hasSwapAll = false;
        addressDescription = "";
        addressPickerText = "";
        fiatAmount = "";
        cryptoAmount = "";
      }
      inputCurrency = _fiatInputMode ? widget.bloc.fiat : currency;
      return Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Container(
            decoration: ShapeDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                                    keyboardType: const TextInputType.numberWithOptions(
                                      signed: false,
                                      decimal: true,
                                    ),
                                    controller: _fiatInputMode
                                        ? fiatAmountController
                                        : amountController,
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        if (state is SwapStateWithInputs) {
                                          final amount = Money.tryParse(value, inputCurrency);
                                          if(amount != null) {
                                            widget.bloc.add(
                                              widget.isReceiverCard
                                                  ? PayoutAmountChanged(amount)
                                                  : DepositAmountChanged(amount),
                                            );
                                          }

                                        }
                                      }
                                    },
                                    inputFormatters: [
                                      if(state is SwapStateWithInputs)
                                        DecimalInputFormatter(
                                            maxDecimals: inputCurrency.decimals),
                                    ],
                                    focusNode: amountFocusNode,
                                    style: TextStyle(
                                      fontSize: 28,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                      hintText: "0",
                                      fillColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              if (_fiatInputMode)
                                Center(
                                  child: Text(
                                    widget.bloc.fiat.title,
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
                              padding: const EdgeInsets.only(top: 4, bottom: 4, left: 4, right: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CakeImageWidget(
                                    imageUrl: currency.iconPath ?? "",
                                    width: 28,
                                    height: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(currency.symbol, textAlign: TextAlign.center),
                                  if (currency.chainIconPath != null) ...[
                                    const SizedBox(width: 4),
                                    CakeImageWidget(
                                      imageUrl: currency.chainIconPath,
                                      width: 12,
                                      height: 12,
                                      colorFilter: ColorFilter.mode(
                                        Theme.of(context).colorScheme.onSurfaceVariant,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ] else
                                    const SizedBox(width: 10),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(9999999999),
                                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
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
                        ),
                      ],
                    ),
                  ),
                  FiatAmountBar(
                    foregroundElementColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    fiatInputMode: _fiatInputMode,
                    onSwitchButtonPressed: () => setState(() => _fiatInputMode = !_fiatInputMode),
                    allAmount: widget.isReceiverCard
                        ? null
                        : widget.bloc.spendingBalance.toString(),
                    allAmountColor: hasSwapAll ? Theme
                        .of(context)
                        .colorScheme
                        .surfaceContainerHigh : Colors.transparent,
                    allAmountTextColor: hasSwapAll ? Theme
                        .of(context)
                        .colorScheme
                        .primary : Theme
                        .of(context)
                        .colorScheme
                        .onSurfaceVariant,
                    onAllButtonPressed: (){
                      if(hasSwapAll) {
                        widget.bloc.add(const SwapAllEnabled());
                      }
                    },
                    cryptoAmount: cryptoAmount,
                    fiatAmount: fiatAmount,
                    cryptoCurrencySymbol: currency.symbol,
                    fiatCurrencySymbol: widget.bloc.fiat.symbol,
                  ),
                  Row(
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
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
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
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        addressDescription,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
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
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!widget.isReceiverCard &&
                          state is SwapStateWithInputs &&
                          state.source is ExternalSwapSource &&
                          (state.source as ExternalSwapSource).refundAddress.isEmpty)
                        ModernButton.svg(
                          svgPath: "assets/new-ui/refund_address.svg",
                          onPressed: askForRefundAddress,
                          size: 36,
                          iconSize: 18,
                          semanticLabel: S.of(context).refund_address,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,),
                      if (widget.isReceiverCard &&
                          state is SwapStateWithInputs &&
                          state.payoutAddress == null) ...[
                        ModernButton.svg(
                          svgPath: "assets/new-ui/paste.svg",
                          onPressed: () async {
                            final text = (await Clipboard.getData("text/plain"))?.text;
                            if (text != null) {
                              widget.bloc.add(PayoutAddressChanged(ExternalSwapAddress(text)));
                            }
                          },

                          size: 36,
                          iconSize: 20,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        semanticLabel: S.of(context).paste,),
                        ModernButton.svg(
                          svgPath: "assets/new-ui/scan.svg",
                          onPressed: () => _presentQRScanner(context),
                          size: 36,
                          iconSize: 20,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,semanticLabel: S.of(context).scan,
                        ),
                      ],
                    ],
                  ),

                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  void _presentCurrencyPicker() {
    if (widget.bloc.state case final SwapStateWithInputs s) {
      final currencies = widget.isReceiverCard
          ? widget.bloc.currencyStore.receiveCurrencies
          : widget.bloc.currencyStore.depositCurrencies;
      final selected = widget.isReceiverCard ? s.depositAmount.currency : s.payoutAmount.currency;
      CurrencyPickerSheet.show(
        context: context,
        args: CurrencyPickerArgs(
          items: currencies,
          selected: selected,
          recentsSource: RecentsSource.trades,
          onSelected: (currency) {
            widget.bloc.add(
              widget.isReceiverCard
                  ? PayoutCurrencyChanged(currency)
                  : DepositCurrencyChanged(currency),
            );
          },
          symbolResolver: (curr) => curr.symbol,
        ),
      );
    }
  }

  Future<void> _presentQRScanner(BuildContext context) async {
    final isCameraPermissionGranted = await PermissionHandler.checkPermission(
      Permission.camera,
      context,
    );
    if (!isCameraPermissionGranted) {
      return;
    }
    final code = await presentQRScanner(context);
    if (code == null) {
      return;
    }
    if (code.isEmpty) {
      return;
    }

    try {
      final uri = Uri.parse(code);
      widget.bloc.add(
        PayoutAddressChanged(ExternalSwapAddress(PaymentRequest.fromUri(uri).address)),
      );
    } catch (_) {}
  }

  void _presentWalletPicker() {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: SwapAddressSelectionModal(
          isSelectingReceiver: widget.isReceiverCard,
          bloc: widget.bloc,
        ),
      ),
    );
  }

  Future<void> askForRefundAddress() async {
    if (widget.bloc.state case final SwapStateWithInputs s) {
      final refundAddress = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RefundAddressModal(
          selectedCurrency: s.depositAmount.currency,
          isFromWalletSelection: true,
        ),
      );
      if (refundAddress != null && refundAddress is String) {
        widget.bloc.add(SourceChanged(ExternalSwapSource(refundAddress)));
      } else {
        widget.bloc.add(const SourceChanged(ExternalSwapSource("")));
      }
    }
  }
}
