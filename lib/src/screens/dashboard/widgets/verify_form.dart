import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class VerifyForm extends StatefulWidget {
  VerifyForm({
    Key? key,
    required this.type,
  }) : super(key: key);

  final WalletType type;

  @override
  VerifyFormState createState() => VerifyFormState();
}

class VerifyFormState extends State<VerifyForm> with AutomaticKeepAliveClientMixin {
  VerifyFormState()
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
      child: Form(
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
            const SizedBox(height: 20),
            AddressTextField(
              controller: addressController,
              options: [AddressTextFieldOption.paste, AddressTextFieldOption.walletAddresses],
              buttonColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              fillColor: Theme.of(context).colorScheme.surface,
              onSelectedContact: (contact) {
                addressController.text = contact.address;
              },
              selectedCurrency: walletTypeToCryptoCurrency(widget.type),
            ),
            const SizedBox(height: 20),
            AddressTextField(
              controller: signatureController,
              placeholder: S.current.signature,
              options: [AddressTextFieldOption.paste],
              buttonColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ],
        ),
      ),
    );
  }
}
