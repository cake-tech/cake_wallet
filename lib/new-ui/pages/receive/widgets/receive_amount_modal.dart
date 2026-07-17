import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/decimal_input_formatter.dart";
import "package:flutter/material.dart";

class ReceiveAmountModal extends StatefulWidget {
  const ReceiveAmountModal({
    required this.initialAmount,
    required this.selectedCurrencySymbol,
    required this.selectedCurrencyDecimals,
    required this.useSatoshi,
    required this.showTokenPicker,
    required this.tokenIconPath,
    required this.tokenTitle,
    required this.onAmountSubmitted,
    required this.onCurrencyPickerTap,
    required this.onTokenPickerTap,
    super.key,
  });

  final String initialAmount;
  final String selectedCurrencySymbol;
  final int selectedCurrencyDecimals;
  final bool useSatoshi;
  final bool showTokenPicker;
  final String tokenIconPath;
  final String tokenTitle;
  final void Function(String amount) onAmountSubmitted;
  final VoidCallback onCurrencyPickerTap;
  final VoidCallback onTokenPickerTap;

  @override
  State<ReceiveAmountModal> createState() => _ReceiveAmountModalState();
}

class _ReceiveAmountModalState extends State<ReceiveAmountModal> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModalTopBar(
                  title: S.of(context).set_amount,
                  onLeadingPressed: Navigator.of(context).pop,
                  onTrailingPressed: () {},
                  leadingIcon: const Icon(Icons.close),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      if (widget.showTokenPicker) ...[
                        const Text("Token"),
                        GestureDetector(
                          onTap: widget.onTokenPickerTap,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    spacing: 8,
                                    children: [
                                      TokenImageWidget(imageUrl: widget.tokenIconPath, size: 32),
                                      Text(widget.tokenTitle.toUpperCase()),
                                    ],
                                  ),
                                  const RotatedBox(
                                    quarterTurns: 2,
                                    child: CakeImageWidget(
                                      imageUrl: "assets/new-ui/dropdown_arrow.svg",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(),
                      Text(S.of(context).amount),
                      Row(
                        children: [
                          Expanded(
                            flex: 75,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  width: 2,
                                ),
                              ),
                              child: TextField(
                                textAlign: TextAlign.left,
                                textAlignVertical: TextAlignVertical.center,
                                controller: _amountController,
                                keyboardType: TextInputType.numberWithOptions(
                                  signed: false,
                                  decimal: widget.selectedCurrencyDecimals > 0,
                                ),
                                inputFormatters: [
                                  DecimalInputFormatter(
                                      maxDecimals: widget.selectedCurrencyDecimals),
                                ],
                                decoration: InputDecoration(
                                  hint: Text(
                                    widget.useSatoshi ? "0" : "0.00000000",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                ),
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 25,
                            child: GestureDetector(
                              onTap: widget.onCurrencyPickerTap,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(18),
                                    bottomRight: Radius.circular(18),
                                  ),
                                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      widget.selectedCurrencySymbol,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(),
                      NewPrimaryButton(
                        text: S.of(context).continue_text,
                        onPressed: () {
                          widget.onAmountSubmitted(_amountController.text);
                          Navigator.of(context).pop();
                        },
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
