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
  WalletRestoreFromKeysFrom({
    required this.walletRestoreViewModel,
    required this.displayWalletPassword,
    this.onPasswordChange,
    Key? key,
    this.onHeightOrDateEntered,})
      : super(key: key);

  final Function(bool)? onHeightOrDateEntered;
  final WalletRestoreViewModel walletRestoreViewModel;
  final bool displayWalletPassword;
  final void Function(String)? onPasswordChange;

  @override
  WalletRestoreFromKeysFromState createState() =>
      WalletRestoreFromKeysFromState(displayWalletPassword: displayWalletPassword);
}

class WalletRestoreFromKeysFromState extends State<WalletRestoreFromKeysFrom> {
  WalletRestoreFromKeysFromState({required bool displayWalletPassword})
      : formKey = GlobalKey<FormState>(),
        blockchainHeightKey = GlobalKey<BlockchainHeightState>(),
        nameController = TextEditingController(),
        addressController = TextEditingController(),
        viewKeyController = TextEditingController(),
        spendKeyController = TextEditingController(),
        nameTextEditingController = TextEditingController(),
        passwordTextEditingController = displayWalletPassword ? TextEditingController() : null;

  final GlobalKey<FormState> formKey;
  final GlobalKey<BlockchainHeightState> blockchainHeightKey;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController viewKeyController;
  final TextEditingController spendKeyController;
  final TextEditingController nameTextEditingController;
  final TextEditingController? passwordTextEditingController;
  void Function()? passwordListener;

  @override
  void initState() {
    if (passwordTextEditingController != null) {
      passwordListener = () => widget.onPasswordChange?.call(passwordTextEditingController!.text);
      passwordTextEditingController?.addListener(passwordListener!);
    }
    super.initState();
  }


  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    viewKeyController.dispose();
    spendKeyController.dispose();
    passwordTextEditingController?.dispose();
    if (passwordListener != null) {
      passwordTextEditingController?.removeListener(passwordListener!);
    }
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
                            .primaryTextTheme!
                            .headline4!
                            .decorationColor!,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.displayWalletPassword)
                Container(
                  padding: EdgeInsets.only(top: 20.0),
                  child: BaseTextFormField(
                    controller: passwordTextEditingController,
                    hintText: S.of(context).password,
                    obscureText: true)),
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
