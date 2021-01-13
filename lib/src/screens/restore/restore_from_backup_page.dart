import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/restore_from_backup_view_model.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:file_picker/file_picker.dart';

class RestoreFromBackupPage extends BasePage {
  RestoreFromBackupPage(this.restoreFromBackupViewModel)
      : textEditingController = TextEditingController();

  final RestoreFromBackupViewModel restoreFromBackupViewModel;
  final TextEditingController textEditingController;

  @override
  String get title => 'Restore from backup';

  @override
  Widget body(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(bottom: 30, left: 25, right: 25),
        child: Column(children: [
          Expanded(
            child: Container(
              child: Center(
                  child: TextFormField(
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                          hintText: 'Enter backup password here'),
                      keyboardType: TextInputType.visiblePassword,
                      controller: textEditingController,
                      style: TextStyle(fontSize: 26, color: Colors.black))),
            ),
          ),
          Container(
              child: Row(children: [
            Expanded(
                child: PrimaryButton(
                    onPressed: () => presentFilePicker(),
                    text: 'Select backup file',
                    color: Colors.grey,
                    textColor: Colors.white)),
            SizedBox(width: 20),
            Expanded(
                child: PrimaryButton(
                    onPressed: () => onImportHandler(context),
                    text: 'Import',
                    color: Theme.of(context).accentTextTheme.body2.color,
                    textColor: Colors.white))
          ])),
        ]));
  }

  Future<void> presentFilePicker() async {
    final result = await FilePicker.platform.pickFiles();

    if (result?.files?.isEmpty ?? true) {
      return;
    }

    restoreFromBackupViewModel.filePath = result.files.first.path;
  }

  Future<void> onImportHandler(BuildContext context) async {
    if (textEditingController.text.isEmpty ||
        (restoreFromBackupViewModel.filePath.isEmpty ?? true)) {
      await showPopUp<void>(
          context: context,
          builder: (_) {
            return AlertWithOneAction(
                alertTitle: S.current.error,
                alertContent:
                    'Please select backup file and enter backup password.',
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });

      return;
    }

    await restoreFromBackupViewModel.import(textEditingController.text);
  }
}
