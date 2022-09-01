import 'package:cake_wallet/view_model/wallet_restore_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/wallet_name_validator.dart';
import 'package:cake_wallet/entities/generate_name.dart';

class WalletRestoreFromKeysFrom extends StatefulWidget {
  WalletRestoreFromKeysFrom({Key key, this.onHeightOrDateEntered, this.walletRestoreViewModel})
      : super(key: key);

  final Function(bool) onHeightOrDateEntered;
  final WalletRestoreViewModel walletRestoreViewModel;

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
        spendKeyController = TextEditingController(),
        nameTextEditingController = TextEditingController();

  final GlobalKey<FormState> formKey;
  final GlobalKey<BlockchainHeightState> blockchainHeightKey;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController viewKeyController;
  final TextEditingController spendKeyController;
  final TextEditingController nameTextEditingController;

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
            Stack(
              alignment: Alignment.centerRight,
              children: [
                BaseTextFormField(
                  controller: nameTextEditingController,
                  hintText: S.of(context).wallet_name,
                  validator: WalletNameValidator(),
                  suffixIcon: IconButton(
                    onPressed: () async {
                      final rName = await generateName();
                      FocusManager.instance.primaryFocus?.unfocus();

                      setState(() {
                        nameTextEditingController.text = rName;
                        nameTextEditingController.selection =
                            TextSelection.fromPosition(TextPosition(
                                offset: nameTextEditingController.text.length));
                      });
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        color: Theme.of(context).hintColor,
                      ),
                      width: 34,
                      height: 34,
                      child: Image.asset(
                        'assets/images/refresh_icon.png',
                        color: Theme.of(context)
                            .primaryTextTheme
                            .display1
                            .decorationColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(height: 20),
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
                hasDatePicker: widget.walletRestoreViewModel.type != WalletType.haven,
                onHeightChange: (_) => null,
                onHeightOrDateEntered: widget.onHeightOrDateEntered)
          ]),
        ));
  }
}
