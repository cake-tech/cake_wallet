import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/edit_backup_password_view_model.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';

class EditBackupPasswordPage extends BasePage {
  EditBackupPasswordPage(this.editBackupPasswordViewModel)
      : textEditingController = TextEditingController() {
    textEditingController.text = editBackupPasswordViewModel.backupPassword;
    textEditingController.addListener(() => editBackupPasswordViewModel
        .backupPassword = textEditingController.text);
  }

  final EditBackupPasswordViewModel editBackupPasswordViewModel;
  final TextEditingController textEditingController;

  @override
  String get title => S.current.edit_backup_password;

  @override
  Widget body(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left: 24, right: 24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
                child: Observer(
                    builder: (_) => TextFormField(
                        autofocus: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        keyboardType: TextInputType.visiblePassword,
                        controller: textEditingController,
                        style: TextStyle(
                            fontSize: 26,
                            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor)))),
            Positioned(
                child: Observer(
                    builder: (_) => PrimaryButton(
                        onPressed: () => onSave(context),
                        text: S.of(context).save,
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        isDisabled: !editBackupPasswordViewModel.canSave)),
                bottom: 24,
                left: 0,
                right: 0)
          ],
        ));
  }

  void onSave(BuildContext context) {
    showPopUp<void>(
        context: context,
        builder: (dialogContext) {
          return AlertWithTwoActions(
              alertTitle: S.of(context).save_backup_password_alert,
              alertContent: S.of(context).change_backup_password_alert,
              rightButtonText: S.of(context).ok,
              leftButtonText: S.of(context).cancel,
              actionRightButton: () async {
                await editBackupPasswordViewModel.save();
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              actionLeftButton: () => Navigator.of(dialogContext).pop());
        });
  }
}
