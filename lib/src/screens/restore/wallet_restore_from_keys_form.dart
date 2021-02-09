import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';

class WalletRestoreFromKeysFrom extends StatefulWidget {
  WalletRestoreFromKeysFrom({Key key, this.onHeightOrDateEntered})
      : super(key: key);

  final Function (bool) onHeightOrDateEntered;

  @override
  WalletRestoreFromKeysFromState createState() =>
      WalletRestoreFromKeysFromState();
}

class WalletRestoreFromKeysFromState extends State<WalletRestoreFromKeysFrom> {
  WalletRestoreFromKeysFromState()
      : formKey = GlobalKey<FormState>(),
        blockchainHeightKey = GlobalKey<BlockchainHeightState>(),
        nameController = TextEditingController(),
        addressController = TextEditingController(),
        viewKeyController = TextEditingController(),
        spendKeyController = TextEditingController();

  final GlobalKey<FormState> formKey;
  final GlobalKey<BlockchainHeightState> blockchainHeightKey;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController viewKeyController;
  final TextEditingController spendKeyController;

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    viewKeyController.dispose();
    spendKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 24, right: 24),
        child: Form(
          key: formKey,
          child: Column(children: <Widget>[
            BaseTextFormField(
                controller: addressController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                hintText: S.of(context).restore_address),
            Container(
                padding: EdgeInsets.only(top: 20.0),
                child: BaseTextFormField(
                    controller: viewKeyController,
                    hintText: S.of(context).restore_view_key_private,
                    maxLines: null)),
            Container(
                padding: EdgeInsets.only(top: 20.0),
                child: BaseTextFormField(
                    controller: spendKeyController,
                    hintText: S.of(context).restore_spend_key_private,
                    maxLines: null)),
            BlockchainHeightWidget(
                key: blockchainHeightKey,
                onHeightChange: (_) => null,
                onHeightOrDateEntered: widget.onHeightOrDateEntered)
          ]),
        ));
  }
}
