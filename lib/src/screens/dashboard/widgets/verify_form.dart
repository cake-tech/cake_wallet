import 'package:cake_wallet/core/wallet_name_validator.dart';
import 'package:cake_wallet/entities/generate_name.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/seed_language_picker.dart';
import 'package:cake_wallet/src/widgets/seed_widget.dart';
import 'package:cake_wallet/themes/extensions/address_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/seed_type_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:polyseed/polyseed.dart';

class VerifyForm extends StatefulWidget {
  VerifyForm({
    Key? key,
    required this.type,
  }) : super(key: key);

  final WalletType type;

  @override
  VerifyFormState createState() => VerifyFormState();
}

class VerifyFormState extends State<VerifyForm> {
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
  Widget build(BuildContext context) {
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
              buttonColor: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 20),
            AddressTextField(
              controller: addressController,
              options: [AddressTextFieldOption.paste, AddressTextFieldOption.walletAddresses],
              buttonColor: Theme.of(context).hintColor,
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
              buttonColor: Theme.of(context).hintColor,
            ),
          ],
        ),
      ),
    );
  }
}
