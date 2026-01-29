import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_address_input.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RefundAddressModal extends StatefulWidget {
  const RefundAddressModal(
      {super.key, this.isFromWalletSelection = false, required this.selectedCurrency});

  final bool isFromWalletSelection;
  final CryptoCurrency selectedCurrency;

  @override
  State<RefundAddressModal> createState() => _RefundAddressModalState();
}

class _RefundAddressModalState extends State<RefundAddressModal> {
  final addressController = TextEditingController();
  bool _textEntered = false;

  @override
  void initState() {
    super.initState();
    addressController.addListener(() {
      setState(() {
        _textEntered = addressController.text.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalTopBar(
            title: S.of(context).set_refund_address,
            trailingIcon: Icon(Icons.close),
            onTrailingPressed: Navigator.of(context).pop,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                spacing: 24,
                children: [
                  SvgPicture.asset(
                    "assets/new-ui/refund_address.svg",
                    colorFilter:
                        ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                  ),
                  Text(
                    S.of(context).return_address_desc +
                        (widget.isFromWalletSelection
                            ? "\n\n${S.of(context).return_address_desc_external}"
                            : ""),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                  Column(
                    spacing: 12,
                    children: [
                      NewSendAddressInput(
                        bottomPadding: true,
                          addressController: addressController,
                          selectedCurrency: widget.selectedCurrency,
                          onEditingComplete: () {}),
                      if (widget.isFromWalletSelection || _textEntered)
                        NewPrimaryButton(
                            onPressed: () {
                              Navigator.of(context).pop(addressController.text);
                            },
                            text: !_textEntered ? S.of(context).skip_set_later : S.of(context).continue_text,
                            color: addressController.text.isEmpty
                                ? Theme.of(context).colorScheme.surfaceContainer
                                : Theme.of(context).colorScheme.primary,
                            textColor: addressController.text.isEmpty
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onPrimary)
                    ],
                  ),
                  SizedBox()
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
