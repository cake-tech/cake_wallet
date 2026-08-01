import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart";
import "package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/decimal_input_formatter.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class NewSendAmountInput extends StatefulWidget {
  const NewSendAmountInput({
    required this.currency,
    required this.maxDecimals,
    required this.hasPicker,
    required this.onPickerClicked,
    required this.currencyIconPath,
    required this.amountController,
    super.key,
    this.validator,
  });

  final String currency;
  final String currencyIconPath;
  final bool hasPicker;
  final int maxDecimals;
  final VoidCallback onPickerClicked;
  final TextEditingController amountController;
  final FormFieldValidator<String>? validator;

  @override
  State<NewSendAmountInput> createState() => _NewSendAmountInputState();
}

class _NewSendAmountInputState extends State<NewSendAmountInput> {
  final formFieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    widget.amountController
        .addListener(() => formFieldKey.currentState?.didChange(widget.amountController.text));
    super.initState();
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
        key: formFieldKey,
        initialValue: widget.amountController.text,
        validator: widget.validator,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.hasPicker
                    ? Theme.of(context).colorScheme.surfaceContainerHigh
                    : Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        spacing: 8,
                        children: [
                          // Deliberately unwrapped. Naming the field with
                          // MergeSemantics > Semantics(label:) made Android announce
                          // the amount twice: FormField's own wrapper node reflects
                          // its descendants' text, so the authored label came back a
                          // second time on the container. The visible "Amount:"
                          // caption on the send page carries the name instead, and it
                          // must stay in the semantics tree for this field to be
                          // named at all.
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.numberWithOptions(
                                signed: false,
                                decimal: widget.maxDecimals > 0,
                              ),
                              autocorrect: false,
                              enableSuggestions: false,
                              inputFormatters: <TextInputFormatter>[
                                DecimalInputFormatter(maxDecimals: widget.maxDecimals),
                              ],
                              controller: widget.amountController,
                              decoration: InputDecoration(
                                hintText: widget.maxDecimals == 0 ? "0" : "0.00",
                                errorMaxLines: 3,
                              ),
                              onChanged: state.didChange,
                            ),
                          ),
                          FloatingIconButton(
                            iconPath: "assets/new-ui/paste.svg",
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              if (data != null && data.text != null) {
                                final text = data.text!;
                                widget.amountController.value = TextEditingValue(
                                  text: text,
                                  selection: TextSelection.collapsed(offset: text.length),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  IntrinsicWidth(
                    child: Observer(
                      // `container: true` is load bearing. FormField wraps this
                      // builder in its own non-container Semantics annotation, so
                      // without a container of its own this configuration is
                      // absorbed into that wrapper node — which then parents the
                      // amount TextField and hides it from screen readers.
                      builder: (_) => Semantics(
                        container: true,
                        button: widget.hasPicker ? true : null,
                        enabled: widget.hasPicker ? true : null,
                        label: widget.hasPicker ? S.of(context).select_asset : widget.currency,
                        value: widget.hasPicker ? widget.currency : null,
                        onTap: widget.hasPicker ? widget.onPickerClicked : null,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: widget.onPickerClicked,
                          child: Container(
                            alignment: Alignment.center,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(18),
                                bottomRight: Radius.circular(18),
                              ),
                              color: widget.hasPicker
                                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                                  : Theme.of(context).colorScheme.surfaceContainer,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                spacing: 8,
                                children: [
                                  if (widget.hasPicker && widget.currencyIconPath.isNotEmpty)
                                    TokenImageWidget(
                                      imageUrl: widget.currencyIconPath,
                                      size: 24,
                                    ),
                                  Text(widget.currency),
                                  if (widget.hasPicker)
                                    CakeImageWidget(
                                      imageUrl: "assets/new-ui/chooser.svg",
                                      width: 12,
                                      height: 12,
                                      colorFilter: ColorFilter.mode(
                                        Theme.of(context).colorScheme.primary,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                ],
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
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: "${S.of(context).amount}${state.errorText!}",
                  excludeSemantics: true,
                  child: Text(
                    state.errorText!,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
          ],
        ),
      );
}
