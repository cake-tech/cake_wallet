import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_edit_or_create_view_model.dart';
import 'package:cake_wallet/core/address_label_validator.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class AddressEditOrCreatePage extends BasePage {
  AddressEditOrCreatePage({required this.addressEditOrCreateViewModel})
      : _formKey = GlobalKey<FormState>(),
        _labelController = TextEditingController(),
        super() {
    _labelController.addListener(
        () => addressEditOrCreateViewModel.label = _labelController.text);
    _labelController.text = addressEditOrCreateViewModel.label;
  }

  final WalletAddressEditOrCreateViewModel addressEditOrCreateViewModel;
  final GlobalKey<FormState> _formKey;
  final TextEditingController _labelController;

  bool _isEffectsInstalled = false;

  @override
  String get title => S.current.new_subaddress_title;

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

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
                          hintText: S.of(context).new_subaddress_label_name,
                          validator: AddressLabelValidator()))),
              Observer(
                builder: (_) => LoadingPrimaryButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await addressEditOrCreateViewModel.save();
                    }
                  },
                  text: addressEditOrCreateViewModel.isEdit
                      ? S.of(context).rename
                      : S.of(context).new_subaddress_create,
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  isLoading:
                      addressEditOrCreateViewModel.state is AddressIsSaving,
                  isDisabled:
                      addressEditOrCreateViewModel.label?.isEmpty ?? true,
                ),
              )
            ],
          ),
        ));
  }

  void _setEffects(BuildContext context) {
    if (_isEffectsInstalled) {
      return;
    }
    reaction((_) => addressEditOrCreateViewModel.state,
            (AddressEditOrCreateState state) {
          if (state is AddressSavedSuccessfully) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => Navigator.of(context).pop());
          }
        });

    _isEffectsInstalled = true;
  }
}