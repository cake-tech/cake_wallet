import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/edit_backup_password_view_model.dart';

class EditBackupPasswordPage extends StatefulWidget {
  EditBackupPasswordPage(this.editBackupPasswordViewModel);

  final EditBackupPasswordViewModel editBackupPasswordViewModel;

  @override
  State<EditBackupPasswordPage> createState() => _EditBackupPasswordPageState();
}

class _EditBackupPasswordPageState extends State<EditBackupPasswordPage> {
  final textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textEditingController.text = widget.editBackupPasswordViewModel.backupPassword;
    textEditingController
        .addListener(() {
      if(textEditingController.text != widget.editBackupPasswordViewModel.backupPassword) {
        widget.editBackupPasswordViewModel.backupPassword = textEditingController.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ModalTopBar(
        title: S.of(context).edit_backup_password,
        leadingIcon: Icon(Icons.arrow_back_ios_new),
        onLeadingPressed: Navigator.of(context).pop,
      ),
      Expanded(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
                left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Observer(
                    builder: (_) => TextFormField(
                      enableSuggestions: false,
                      autocorrect: false,
                      keyboardType: TextInputType.visiblePassword,
                      controller: textEditingController,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                ),
                Positioned(
                  child: Observer(
                    builder: (_) => PrimaryButton(
                      onPressed: () => onSave(context),
                      text: S.of(context).save,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      isDisabled: !widget.editBackupPasswordViewModel.canSave,
                    ),
                  ),
                  bottom: 24,
                  left: 0,
                  right: 0,
                )
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  void onSave(BuildContext context) {
    FocusScope.of(context).unfocus();
    showPopUp<void>(
        context: context,
        builder: (dialogContext) {
          return AlertWithTwoActions(
              alertTitle: S.of(context).save_backup_password_alert,
              alertContent: S.of(context).change_backup_password_alert,
              rightButtonText: S.of(context).ok,
              leftButtonText: S.of(context).cancel,
              actionRightButton: () async {
                widget.editBackupPasswordViewModel.backupPassword = textEditingController.text;
                await widget.editBackupPasswordViewModel.save();
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              actionLeftButton: () => Navigator.of(dialogContext).pop());
        });
  }
}
