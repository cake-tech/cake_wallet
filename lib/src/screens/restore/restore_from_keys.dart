import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';

class RestoreFromKeysFrom extends StatefulWidget {
  @override
  _RestoreFromKeysFromState createState() => _RestoreFromKeysFromState();
}

class _RestoreFromKeysFromState extends State<RestoreFromKeysFrom> {
  final _formKey = GlobalKey<FormState>();
  final _blockchainHeightKey = GlobalKey<BlockchainHeightState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _viewKeyController = TextEditingController();
  final _spendKeyController = TextEditingController();
  final _wifController = TextEditingController();

  @override
  void initState() {
    // _nameController.addListener(() =>
    // widget.walletRestorationFromKeysVM.name = _nameController.text);
    // _addressController.addListener(() =>
    // widget.walletRestorationFromKeysVM.address = _addressController.text);
    // _viewKeyController.addListener(() =>
    // widget.walletRestorationFromKeysVM.viewKey = _viewKeyController.text);
    // _spendKeyController.addListener(() =>
    // widget.walletRestorationFromKeysVM.spendKey = _spendKeyController.text);
    // _wifController.addListener(() =>
    // widget.walletRestorationFromKeysVM.wif = _wifController.text);

    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _viewKeyController.dispose();
    _spendKeyController.dispose();
    _wifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 24, right: 24),
      child: Form(
        key: _formKey,
        child: Column(children: <Widget>[
          BaseTextFormField(
            controller: _addressController,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            hintText: S.of(context).restore_address,
          ),
          Container(
              padding: EdgeInsets.only(top: 20.0),
              child: BaseTextFormField(
                controller: _viewKeyController,
                hintText: S.of(context).restore_view_key_private,
              )),
          Container(
              padding: EdgeInsets.only(top: 20.0),
              child: BaseTextFormField(
                controller: _spendKeyController,
                hintText: S.of(context).restore_spend_key_private,
              )),
          BlockchainHeightWidget(
              key: _blockchainHeightKey,
              onHeightChange: (height) {
                // widget.walletRestorationFromKeysVM.height = height;
                print(height);
              }),
        ]),
      ),
    );
  }
}
