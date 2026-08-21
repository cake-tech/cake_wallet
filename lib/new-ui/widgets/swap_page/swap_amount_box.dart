import "package:cake_wallet/entities/qr_scanner.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/send_page/fiat_amount_bar.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/refund_address_modal.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_address_selection_modal.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/decimal_input_formatter.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cake_wallet/utils/permission_handler.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:permission_handler/permission_handler.dart";

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
  void initState() {
    super.initState();
    amountFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<SwapBloc, SwapState>(
    listener: (context, state) {
      if (state is SwapStateWithInputs) {
        final amount = widget.isReceiverCard ? state.payoutAmount : state.depositAmount;

        final changed = _fiatInputMode
            ? double.tryParse(amount.fiatAmount.toString()) != double.tryParse(fiatAmountController.text)
            : double.tryParse(amount.cryptoAmount.toString()) != double.tryParse(amountController.text);

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
      final bool isSwapAll;
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
        isSwapAll = !widget.isReceiverCard && state.depositAmount.isSwapAll;
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
        isSwapAll = false;
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
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      TextFormField(
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
                                        style: const TextStyle(
                                          fontSize: 28,
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
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: AnimatedOpacity(
                                            duration: const Duration(milliseconds: 150),
                                            opacity: !isSwapAll || amountFocusNode.hasFocus
                                                ? 0
                                                : 1,
                                            child: ExcludeSemantics(
                                              child: ColoredBox(
                                                color: Theme.of(context).colorScheme.surfaceContainer,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    S.of(context).all,
                                                    style: const TextStyle(
                                                      fontSize: 28,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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

  String? _getCurrencyChainIconPath(CryptoCurrency curr) {
    try {
      if (curr.chainIconPath != null) {
        return curr.chainIconPath!;
      }

      if (curr.tag != null) {
        final currencyFromTag = CryptoCurrency.fromString(curr.tag!);

        if (currencyFromTag.chainIconPath != null) {
          return currencyFromTag.chainIconPath!;
        }
      }
    } catch (_) {}
    return null;
  }
}
