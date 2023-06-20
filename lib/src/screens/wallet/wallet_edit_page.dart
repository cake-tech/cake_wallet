import 'package:cake_wallet/core/wallet_name_validator.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:mobx/mobx.dart';

class WalletEditPage extends BasePage {
  WalletEditPage(
      {required this.walletListViewModel,
      required this.editingWallet,
      required this.removeWallet})
      : _formKey = GlobalKey<FormState>(),
        _labelController = TextEditingController(),
        super() {
    reaction((_) => walletListViewModel.newName, (String newName) {
      walletListViewModel.newName = newName;
    });
    _labelController
        .addListener(() => walletListViewModel.newName = _labelController.text);
    _labelController.text = editingWallet.name;
  }

  final GlobalKey<FormState> _formKey;
  final TextEditingController _labelController;

  final WalletListViewModel walletListViewModel;
  final WalletListItem editingWallet;
  final Future<void> Function(WalletListItem) removeWallet;

  @override
  String get title => S.current.wallet_list_edit_wallet;

  @override
  Widget body(BuildContext context) {
    return Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: Center(
                      child: BaseTextFormField(
                          controller: _labelController,
                          hintText: S.of(context).wallet_list_wallet_name,
                          validator: WalletNameValidator()))),
              Observer(
                  builder: (_) => Row(
                        children: <Widget>[
                          Flexible(
                              child: Container(
                            padding: EdgeInsets.only(right: 8.0),
                            child: LoadingPrimaryButton(
                                onPressed: () {
                                  removeWallet(editingWallet);
                                  Navigator.of(context).pop();
                                },
                                text: S.of(context).delete,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .bodyLarge!
                                    .backgroundColor!,
                                textColor: Colors.white),
                          )),
                          Flexible(
                              child: Container(
                            padding: EdgeInsets.only(left: 8.0),
                            child: LoadingPrimaryButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  walletListViewModel.changeName(editingWallet);
                                  Navigator.of(context).pop();
                                }
                              },
                              text: S.of(context).save,
                              color: Theme.of(context)
                                  .accentTextTheme
                                  .bodyLarge!
                                  .color!,
                              textColor: Colors.white,
                              isDisabled: walletListViewModel.newName.isEmpty,
                            ),
                          )),
                        ],
                      ))
            ],
          ),
        ));
  }
}
