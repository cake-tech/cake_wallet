import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignForm extends StatefulWidget {
  SignForm({
    Key? key,
    required this.type,
    required this.includeAddress,
  }) : super(key: key);

  final WalletType type;
  final bool includeAddress;

  @override
  SignFormState createState() => SignFormState();
}

class SignFormState extends State<SignForm> with AutomaticKeepAliveClientMixin {
  SignFormState()
      : formKey = GlobalKey<FormState>(),
        messageController = TextEditingController(),
        addressController = TextEditingController(),
        signatureController = TextEditingController();

  final TextEditingController messageController;
  final TextEditingController addressController;
  final TextEditingController signatureController;
  final GlobalKey<FormState> formKey;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      padding: EdgeInsets.only(left: 24, right: 24),
      child: Column(
        children: [
          Form(
              key: formKey,
              child: Column(
                children: [
                  AddressTextField(
                    controller: messageController,
                    placeholder: S.current.message,
                    options: [AddressTextFieldOption.paste],
                    buttonColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  if (widget.includeAddress) ...[
                    const SizedBox(height: 20),
                    AddressTextField(
                      controller: addressController,
                      options: [
                        AddressTextFieldOption.paste,
                        AddressTextFieldOption.walletAddresses
                      ],
                      buttonColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      onSelectedContact: (contact) {
                        addressController.text = contact.$2;
                      },
                      selectedCurrency: walletTypeToCryptoCurrency(widget.type),
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ],
                ],
              )),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final text = signatureController.text;
              if (text.isEmpty) {
                return;
              }
              Clipboard.setData(ClipboardData(text: text));
              showBar<void>(context, S.of(context).transaction_details_copied(text));
            },
            child: BaseTextFormField(
              enabled: false,
              controller: signatureController,
              hintText: S.current.signature,
            ),
          ),
        ],
      ),
    );
  }
}
