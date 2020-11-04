import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_edit_name_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class EditWalletNamePage extends BasePage {
  EditWalletNamePage(this.walletEditNameVM)
      : _formKey = GlobalKey<FormState>(),
      _nameController = TextEditingController(),
      super() {
    _nameController.text = walletEditNameVM.displayName;
    _nameController
        .addListener(() => walletEditNameVM.displayName = _nameController.text);
  }

  final WalletEditNameVM walletEditNameVM;
  final GlobalKey<FormState> _formKey;
  final TextEditingController _nameController;

  @override
  String get title => S.current.wallet_name;

  @override
  Widget body(BuildContext context) {
    reaction((_) => walletEditNameVM.state, (ExecutionState state) {
      if (state is FailureState) {
        _onContactSavingFailure(context, state.error);
      }

      if (state is ExecutedSuccessfullyState) {
        _onContactSavedSuccessfully(context);
      }
    });

    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
                child: Center(
                  child: BaseTextFormField(
                    controller: _nameController,
                    hintText: S.of(context).wallet_name,
                    validator: WalletNameValidator(),
                  ),
                )),
            Observer(
                builder: (_) => PrimaryButton(
                    onPressed: () => _confirmForm(context),
                    text: S.of(context).rename,
                    color: Theme.of(context).accentTextTheme.body2.color,
                    textColor: Colors.white,
                    isDisabled: !walletEditNameVM.isReady))
          ],
        ),
      ),
    );
  }

  void _confirmForm(BuildContext context) {
    if (!_formKey.currentState.validate()) {
      return;
    }

    if (walletEditNameVM.isWalletNameExists()) {
      showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: S.current.wallet_name,
                alertContent: 'Wallet with the same name is exists',
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
    } else {
      walletEditNameVM.save();
    }
  }

  void _onContactSavingFailure(BuildContext context, String error) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
              alertTitle: S.current.wallet_name,
              alertContent: error,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop());
        });
  }

  void _onContactSavedSuccessfully(BuildContext context) =>
      Navigator.of(context).pop();
}