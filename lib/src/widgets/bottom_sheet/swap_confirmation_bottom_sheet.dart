import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/rates/rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/swap_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/utils/debounce.dart";
import "package:cake_wallet/view_model/payment/payment_view_model.dart";
import "package:cw_core/amount/amount_sanitizer.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";

class SwapConfirmationBottomSheet extends BaseBottomSheet {
  SwapConfirmationBottomSheet({
    required this.bloc, required this.paymentFlowResult,
    required this.authService,
    this.sessionId,
  }) : super(
    titleText: S.current.swap,
    footerType: FooterType.none,
    maxHeight: 900,
  );

  final PaymentFlowResult paymentFlowResult;
  final AuthService authService;
  final SwapBloc bloc;
  final String? sessionId;
  @override
  Widget contentWidget(BuildContext context) => SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SwapConfirmationContent(
        paymentFlowResult: paymentFlowResult,
        authService: authService, bloc: bloc,
      ),
    );
}

class SwapConfirmationContent extends StatefulWidget {
  const SwapConfirmationContent({
    required this.bloc, required this.paymentFlowResult, required this.authService, super.key,
  });

  final SwapBloc bloc;
  final PaymentFlowResult paymentFlowResult;
  final AuthService authService;

  @override
  SwapConfirmationContentState createState() => SwapConfirmationContentState();
}

class SwapConfirmationContentState extends State<SwapConfirmationContent> {
  late TextEditingController _amountController;
  late TextEditingController _amountFiatController;
  late TextEditingController _addressController;

  final _receiveAmountDebounce = Debounce(const Duration(milliseconds: 500));
  final _receiveAmountFiatDebounce = Debounce(const Duration(milliseconds: 500));
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _amountFiatFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  ReactionDisposer? _receiveAmountReaction;
  ReactionDisposer? _receiveAddressReaction;
  ReactionDisposer? _tradeStateReaction;
  ReactionDisposer? _bestRateReaction;
  ReactionDisposer? _receiveAmountFiatReaction;

  bool _showingFailureDialog = false;
  bool _showingSwapDetailsDialog = false;
  bool _isUserTypingFiat = false;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.paymentFlowResult.addressDetectionResult?.address ?? "");
    _amountController = TextEditingController(
        text: widget.paymentFlowResult.addressDetectionResult?.amount?.isNotEmpty ?? false
            ? widget.paymentFlowResult.addressDetectionResult?.amount
            : "0.00");
    _amountFiatController =
        TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _setUpReactions(
        context,
        widget.paymentFlowResult,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFiatController.dispose();
    _addressController.dispose();
    _amountFocus.dispose();
    _amountFiatFocus.dispose();
    _addressFocus.dispose();
    _receiveAmountReaction?.call();
    _receiveAddressReaction?.call();
    _tradeStateReaction?.call();
    _bestRateReaction?.call();
    _receiveAmountFiatReaction?.call();
    _showingFailureDialog = false;
    _showingSwapDetailsDialog = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detectedCurrency = widget.paymentFlowResult.detectedCurrency!;

    return BlocBuilder<SwapBloc, SwapState>(
  builder: (context, state) {

    final Money depositAmount;
    final Money payoutAmount;
    final ExchangeProviderDescription provider;
    final String sourceString;
    final bool isExternal;
    final String tradeId;
    final String payoutAddress;
    if(state is SwapStateWithInputs) {
      depositAmount = state.depositAmount.cryptoAmount;
      payoutAmount = state.payoutAmount.cryptoAmount;
      provider = state.usableProviders.first;
      sourceString = state.source.displayName;
      isExternal = state.source is ExternalSwapSource;
      tradeId = "";
      payoutAddress = state.payoutAddress?.address ?? "";
    } else if(state is SwapStateWithTrade) {
      depositAmount = state.trade.depositAmount;
      payoutAmount = state.trade.payoutAmount;
      provider =state.trade.provider;
      sourceString = state.source.displayName;
      isExternal = state.source is ExternalSwapSource;
      tradeId = state.trade.id;
      payoutAddress = state.trade.payoutAddress;
    } else {
      throw StateError("should not be openable at this point");
    }

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CakeImageWidget(
                  imageUrl: depositAmount.currency.iconPath!,
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, size: 24),
                const SizedBox(width: 12),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CakeImageWidget(
                      imageUrl: detectedCurrency.iconPath ?? "",
                      width: 32,
                      height: 32,
                    ),
                    if (isEVMCompatibleChain(widget.paymentFlowResult.walletType!)) ...[
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: CakeImageWidget(
                          imageUrl: getCryptoCurrencyIconForWalletListItem(
                            widget.paymentFlowResult.walletType!,
                            chainId: widget.paymentFlowResult.chainId,
                          ),
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwapConfirmationTextfield(
              key: const ValueKey("swap_confirmation_bottomsheet_amount_textfield_key"),
              hintText: "Amount (${detectedCurrency})",
              focusNode: _amountFocus,
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r"[\-| ]")),
              ],
              onChanged: (value) {
                final sanitized = value
                    .sanitized()
                    .withMaxDecimals(payoutAmount.currency.decimals);
                if (sanitized != _amountController.text) {
                  // Update text while preserving a sane cursor position to avoid auto-selection
                  _amountController.value = _amountController.value.copyWith(
                    text: sanitized,
                    selection: TextSelection.collapsed(offset: sanitized.length),
                    composing: TextRange.empty,
                  );
                }
              },
            ),
            Observer(
              builder: (_) {
                String? min = "0.0";
                String? max = "0.0";

                final limitsState = widget.bloc.rateCubit.state;
                if (limitsState is RatesLoaded) {
                  min = limitsState.minLimit?.toString();
                  max = limitsState.maxLimit?.toString();
                }

                if (limitsState is RatesLoading) {
                  min = "...";
                  max = "...";
                }
                if (min != null || max != null) {
                  return SizedBox(
                    height: 15,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        min != null
                            ? Text(
                          key: const ValueKey("min_limit_text_key"),
                          S.of(context).min_value(min, detectedCurrency.toString()),
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontSize: 10,
                            height: 1.2,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                            : const Offstage(),
                        min != null ? const SizedBox(width: 10) : const Offstage(),
                        max != null
                            ? Text(
                          key: const ValueKey("max_limit_text_key"),
                          S.of(context).max_value(max, detectedCurrency.toString()),
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontSize: 10,
                            height: 1.2,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                            : const Offstage(),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 8),
            SwapConfirmationTextfield(
              key: const ValueKey("swap_confirmation_bottomsheet_amount_fiat_textfield_key"),
              hintText: "Amount (${widget.bloc.fiat.title})",
              focusNode: _amountFiatFocus,
              controller: _amountFiatController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            SwapConfirmationTextfield(
              key: const ValueKey("swap_confirmation_bottomsheet_address_textfield_key"),
              isAddress: true,
              walletType:
              cryptoCurrencyOrTokenToWalletType(depositAmount.currency as CryptoCurrency),
              hintText: "Destination Address",
              focusNode: _addressFocus,
              controller: _addressController,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Tap field to edit values",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SwapConfirmationFooter(
              formKey: _formKey,
              bloc: widget.bloc,
              authService: widget.authService,
            ),
          ],
        ),
      ),
    );
  },
);
  }

  Future<void> _setUpReactions(
      BuildContext context,
      PaymentFlowResult paymentFlowResult,
      ) async {


  widget.bloc.add(PayoutAddressChanged(ExternalSwapAddress(_addressController.text)));

  widget.bloc.add(PayoutAmountChanged(Money.parse(_amountController.text, paymentFlowResult.detectedCurrency!)));
    // _amountFiatController.text = exchangeViewModel.receiveAmountFiatFormatted;
    // exchangeViewModel.isReceiveAmountEntered = true;
    // exchangeViewModel.isFixedRateMode = true;
  }
}

class SwapConfirmationTextfield extends StatelessWidget {
  const SwapConfirmationTextfield({
    required this.focusNode, required this.controller, required this.hintText, super.key,
    this.walletType,
    this.isAddress = false,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final String hintText;
  final WalletType? walletType;
  final bool isAddress;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: focusNode.hasFocus
              ? BorderSide(color: Theme.of(context).colorScheme.primary)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hintText,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (isAddress) const SizedBox(height: 8),
          isAddress
              ? AddressFormatter.buildSegmentedAddress(
            address: controller.text,
            walletType: walletType,
            evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          )
              : BaseTextFormField(
            isDense: true,
            hintText: hintText,
            focusNode: focusNode,
            hasUnderlineBorder: true,
            borderWidth: 0,
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
          ),
        ],
      ),
    );
}

class SwapConfirmationFooter extends StatelessWidget {
  const SwapConfirmationFooter({
 required this.bloc, required this.formKey, required this.authService, super.key,
  });

  final AuthService authService;
  final SwapBloc bloc;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) => Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: BlocBuilder<SwapBloc, SwapState>(
        bloc: bloc,
        builder: (context, state) {

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                text: S.current.cancel,
                onPressed:  () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(null);
                  }
                },
                color: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(height: 12),
              LoadingPrimaryButton(
                text: S.current.continue_text,
                onPressed:  () {
                  FocusScope.of(context).unfocus();

                  if (formKey.currentState != null && formKey.currentState!.validate()) {
                    authService.authenticateAction(
                      context,
                      conditionToDetermineIfToUse2FA: false,
                      onAuthSuccess: (value) {
                        if (value) {
                          bloc.add(SwapInitiated());
                        }
                      },
                    );
                  }
                }
                   ,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          );
        },
      ),
    );
}
