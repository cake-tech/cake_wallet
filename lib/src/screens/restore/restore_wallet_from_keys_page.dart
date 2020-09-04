import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/view_model/wallet_restoration_from_keys_vm.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';

class RestoreWalletFromKeysPage extends BasePage {
  RestoreWalletFromKeysPage(
      {@required this.walletRestorationFromKeysVM});

  final WalletRestorationFromKeysVM walletRestorationFromKeysVM;

  @override
  String get title => S.current.restore_title_from_keys;

  @override
  Widget body(BuildContext context) => RestoreFromKeysFrom(walletRestorationFromKeysVM);
}

class RestoreFromKeysFrom extends StatefulWidget {
  RestoreFromKeysFrom(this.walletRestorationFromKeysVM);

  final WalletRestorationFromKeysVM walletRestorationFromKeysVM;

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
    _nameController.addListener(() =>
    widget.walletRestorationFromKeysVM.name = _nameController.text);
    _addressController.addListener(() =>
    widget.walletRestorationFromKeysVM.address = _addressController.text);
    _viewKeyController.addListener(() =>
    widget.walletRestorationFromKeysVM.viewKey = _viewKeyController.text);
    _spendKeyController.addListener(() =>
    widget.walletRestorationFromKeysVM.spendKey = _spendKeyController.text);
    _wifController.addListener(() =>
    widget.walletRestorationFromKeysVM.wif = _wifController.text);

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

    /*reaction((_) => walletRestorationStore.state, (WalletRestorationState state) {
      if (state is WalletRestoredSuccessfully) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      if (state is WalletRestorationFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.current.restore_title_from_keys,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop()
                );
              });
        });
      }
    });*/

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(bottom: 24.0),
        content: Form(
          key: _formKey,
          child: Column(children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                    child: Container(
                      padding: EdgeInsets.only(top: 20.0),
                      child: BaseTextFormField(
                        controller: _nameController,
                        hintText: S.of(context).restore_wallet_name,
                        validator: WalletNameValidator(),
                      )
                    ))
              ],
            ),
            if (!widget.walletRestorationFromKeysVM.hasRestorationHeight)
            Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    padding: EdgeInsets.only(top: 20.0),
                    child: BaseTextFormField(
                      controller: _wifController,
                      hintText: 'WIF',
                    )
                ))
              ],
            ),
            if (widget.walletRestorationFromKeysVM.hasRestorationHeight) ... [
            Row(
              children: <Widget>[
                Flexible(
                    child: Container(
                      padding: EdgeInsets.only(top: 20.0),
                      child: BaseTextFormField(
                        controller: _addressController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        hintText: S.of(context).restore_address,
                      )
                    ))
              ],
            ),
            Row(
              children: <Widget>[
                Flexible(
                    child: Container(
                      padding: EdgeInsets.only(top: 20.0),
                      child: BaseTextFormField(
                        controller: _viewKeyController,
                        hintText: S.of(context).restore_view_key_private,
                      )
                    ))
              ],
            ),
            Row(
              children: <Widget>[
                Flexible(
                    child: Container(
                      padding: EdgeInsets.only(top: 20.0),
                      child: BaseTextFormField(
                        controller: _spendKeyController,
                        hintText: S.of(context).restore_spend_key_private,
                      )
                    ))
              ],
            ),
            BlockchainHeightWidget(
              key: _blockchainHeightKey,
              onHeightChange: (height) {
                widget.walletRestorationFromKeysVM.height = height;
                print(height);
            })],
          ]),
        ),
        bottomSectionPadding: EdgeInsets.only(bottom: 24),
        bottomSection: Observer(builder: (_) {
          return LoadingPrimaryButton(
            onPressed: () {
              if (_formKey.currentState.validate()) {
                /*walletRestorationStore.restoreFromKeys(
                    name: _nameController.text,
                    language: seedLanguageStore.selectedSeedLanguage,
                    address: _addressController.text,
                    viewKey: _viewKeyController.text,
                    spendKey: _spendKeyController.text,
                    restoreHeight: _blockchainHeightKey.currentState.height);*/
              }
            },
            text: S.of(context).restore_recover,
            color: Palette.blueCraiola,
            textColor: Colors.white,
            //isDisabled: walletRestorationStore.disabledState,
          );
        }),
      ),
    );
  }
}
