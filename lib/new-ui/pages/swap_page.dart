import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/address_resolver/address_resolver_service.dart";
import "package:cake_wallet/core/address_resolver/parsed_address.dart";
import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_presentation_event.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/rates/rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cake_wallet/new-ui/widgets/hardware_wallet/connect_hardware_wallet.dart";
import "package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_memo_input.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_syncing_indicator.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/anypay_swap_footer.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/provider_selector_page.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/refund_address_modal.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_amount_box.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_confirm_sheet.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_from_send_args.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_limit_popup.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_options_page.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_source_selector.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/sync_status.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class NewSwapPage extends StatefulWidget {
  NewSwapPage(
    this.bloc,
    this.authService,
    this.initialPaymentRequest, {
      this.fromSend,
    CryptoCurrency? initialCurrency,
  }) {
    if (initialCurrency != null) {
      bloc.add(DepositCurrencyChanged(initialCurrency));
    }
  }

  final SwapBloc bloc;
  final AuthService authService;
  final PaymentRequest? initialPaymentRequest;
  final SwapFromSendArgs? fromSend;

  @override
  State<NewSwapPage> createState() => _NewSwapPageState();
}

class _NewSwapPageState extends State<NewSwapPage> {
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPaymentRequest != null) {
        final newCurr = CryptoCurrency.fromString(widget.initialPaymentRequest!.scheme);
        widget.bloc.add(
          InitialValuesApplied(
            depositCurrency: newCurr,
            depositAmount: Money.tryParse(widget.initialPaymentRequest!.amount, newCurr),
            payoutAddress: ExternalSwapAddress(widget.initialPaymentRequest!.address),
          ),
        );
      }

      if (widget.fromSend != null) {
        widget.bloc.add(
          InitialValuesApplied(
            payoutCurrency: widget.fromSend!.receiveCurrency,
            payoutAmount: widget.fromSend!.receiveAmount,
            payoutAddress: ExternalSwapAddress(widget.fromSend!.recipientAddress),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

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
          AddressValidationFailed(:final currency) => _showAddressValidationFailurePopup(currency),
          AliaspayAddressFound(:final address) => _showParsedAddressPopup(address),
          SwapCreationStarted() => _showConfirmSheet(),
          SwapAllNotReady() => _showSwapAllNotReadyPopup(),
          LowFeeAlert() => Future.delayed(const Duration(seconds: 1), _showFeeAlert),
          WalletSwitchFailed(:final error) => _showWalletSwitchFailedPopup(error),
          RefundAddressRequired(:final currency) => _askForRefundAddress(currency),
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
                                    if(widget.fromSend != null)
                                      SwapSourceSelector(bloc: widget.bloc)
                                    else
                                    SwapAmountBox(isReceiverCard: false, bloc: widget.bloc),
                                    SwapLimitPopup(bloc: widget.bloc),
                                    if (widget.fromSend != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 24),
                                        child: Icon(
                                          Icons.arrow_downward,
                                          size: 24,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
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
                                    SwapAmountBox(
                                      isReceiverCard: true,
                                      bloc: widget.bloc,
                                      network: widget.fromSend?.targetWalletType,
                                    ),
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
                            Observer(builder:(context){
              if (widget.bloc.wallet.syncStatus is! SyncedSyncStatus) {
                return SendSyncingIndicator(status: widget.bloc.wallet.syncStatus);
              }return const SizedBox.shrink();

                            }),
                            if (widget.fromSend == null && widget.bloc.state is SwapStateWithInputs &&
                                (widget.bloc.state as SwapStateWithInputs).isFixedRate)
                              Text(
                                S.of(context).exchange_rate_is_fixed,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            if(widget.fromSend != null)
                              AnyPaySwapFooter(bloc: widget.bloc),
                            if(widget.fromSend == null)
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
                                      conditionToDetermineIfToUse2FA: _requiresTotp,
                                      onAuthSuccess: (value) async {
                                        if (value && await _connectHardwareWallet()) {
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

  Future<void> _showFeeAlert() async {
    if (mounted) {
      final confirmed = await showPopUp<bool>(
          context: context,
          builder: (dialogContext) =>
              AlertWithTwoActions(
                  alertTitle: S
                      .of(context)
                      .low_fee,
                  alertContent: S
                      .of(context)
                      .low_fee_alert,
                  leftButtonText: S
                      .of(context)
                      .ignor,
                  rightButtonText: S
                      .of(context)
                      .use_suggested,
                  actionLeftButton: () => Navigator.of(dialogContext).pop(false),
                  actionRightButton: () => Navigator.of(dialogContext).pop(true))) ??
          false;
      if (confirmed) {
        widget.bloc.add(DefaultFeeSelected());
      }
    }
  }


  bool get _requiresTotp => switch (widget.bloc.state) {
    SwapStateWithInputs(payoutAddress: InternalWalletSwapAddress()) =>
      widget.authService.settingsStore.shouldRequireTOTP2FAForExchangesToInternalWallets,
    _ => widget.authService.settingsStore.shouldRequireTOTP2FAForExchangesToExternalWallets,
  };

  Future<bool> _connectHardwareWallet() async {
    final wallet = widget.bloc.wallet;
    final isSentFromWallet = switch (widget.bloc.state) {
      SwapStateWithInputs(:final source) => source is InternalSwapSource,
      _ => false,
    };

    if (!wallet.isHardwareWallet || !isSentFromWallet) {
      return true;
    }

    return mounted &&
        await connectHardwareWallet(
          context,
          wallet,
          getIt<HardwareWalletViewModel>(param1: wallet.hardwareWalletType!),
        );
  }

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

  Future<void> _askForRefundAddress(CryptoCurrency currency) async {
    final refundAddress = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RefundAddressModal(selectedCurrency: currency),
    );
    if (refundAddress != null && refundAddress.isNotEmpty) {
      widget.bloc.add(SourceChanged(ExternalSwapSource(refundAddress), initiateSwap: true));
    }
  }

  Future<void> _showAddressValidationFailurePopup(CryptoCurrency currency) async {
    await showPopUp(
      context: context,
      builder: (context) => AlertWithOneAction(
        alertTitle: S.of(context).invalid_address,
        alertContent:
            "${S.of(context).invalid_address_desc} ${currency.fullName ?? currency.symbol}.",
        buttonText: S.of(context).ok,
        buttonAction: Navigator.of(context).pop,
      ),
    );
  }

  Future<void> _showWalletSwitchFailedPopup(Object error) async {
    await showPopUp(
      context: context,
      builder: (context) => AlertWithOneAction(
        alertTitle: S.of(context).error,
        alertContent: error.toString(),
        buttonText: S.of(context).ok,
        buttonAction: Navigator.of(context).pop,
      ),
    );
  }

  Future<void> _showSwapAllNotReadyPopup() async {
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
  late final TextEditingController memoController;

  @override
  void initState() {
    super.initState();
    memoController = TextEditingController()
      ..addListener(() => widget.bloc.add(MemoChanged(memoController.text)));
  }

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

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
                            colorFilter: forcedProvider != null ? null : ColorFilter.mode(Theme
                                .of(context)
                                .colorScheme
                                .error, BlendMode.srcIn),
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
