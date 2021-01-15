import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/edit_backup_password_view_model.dart';

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
  String get title => 'Edit Backup Password';

  @override
  Widget body(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left: 20, right: 20),
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
                        style: TextStyle(fontSize: 26, color: Colors.black)))),
            Positioned(
                child: Observer(
                    builder: (_) => PrimaryButton(
                        onPressed: () => onSave(context),
                        text: 'Save',
                        color: Theme.of(context).accentTextTheme.body2.color,
                        textColor: Colors.white,
                        isDisabled: !editBackupPasswordViewModel.canSave)),
                bottom: 30,
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
              alertTitle: 'Save backup password',
              alertContent:
                  'Your previous backup files will be not available to import with new backup password. New backup password will be used only for new backup files. Are you sure that you want to change backup password ?',
              rightButtonText: S.of(context).ok,
              leftButtonText: S.of(context).cancel,
              actionRightButton: () async {
                await editBackupPasswordViewModel.save();
                Navigator.of(dialogContext)..pop()..pop();
              },
              actionLeftButton: () => Navigator.of(dialogContext).pop());
        });
  }
}
