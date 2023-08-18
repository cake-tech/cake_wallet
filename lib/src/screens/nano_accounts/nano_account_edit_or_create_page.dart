import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/view_model/nano_account_list/nano_account_edit_or_create_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/monero_account_label_validator.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';

class NanoAccountEditOrCreatePage extends BasePage {
  NanoAccountEditOrCreatePage({required this.nanoAccountCreationViewModel})
      : _formKey = GlobalKey<FormState>(),
        _textController = TextEditingController() {
    _textController.addListener(() => nanoAccountCreationViewModel.label = _textController.text);
    _textController.text = nanoAccountCreationViewModel.label;
  }

  final NanoAccountEditOrCreateViewModel nanoAccountCreationViewModel;

  @override
  String get title => S.current.account;

  final GlobalKey<FormState> _formKey;
  final TextEditingController _textController;

  @override
  Widget body(BuildContext context) => Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: Center(
                      child: BaseTextFormField(
                controller: _textController,
                hintText: S.of(context).account,
                validator: MoneroLabelValidator(),
              ))),
              Observer(
                  builder: (_) => LoadingPrimaryButton(
                        onPressed: () async {
                          if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
                            return;
                          }

                          await nanoAccountCreationViewModel.save();

                          Navigator.of(context).pop(_textController.text);
                        },
                        text: nanoAccountCreationViewModel.isEdit
                            ? S.of(context).rename
                            : S.of(context).add,
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        isLoading: nanoAccountCreationViewModel.state is IsExecutingState,
                        isDisabled: nanoAccountCreationViewModel.label?.isEmpty ?? true,
                      ))
            ],
          ),
        ),
      );
}
