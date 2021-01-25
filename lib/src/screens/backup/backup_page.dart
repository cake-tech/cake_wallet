import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/backup_view_model.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class BackupPage extends BasePage {
  BackupPage(this.backupViewModelBase);

  final BackupViewModelBase backupViewModelBase;

  @override
  String get title => 'Backup';

  @override
  Widget trailing(BuildContext context) => TrailButton(
      caption: 'Change password',
      onPressed: () =>
          Navigator.of(context).pushNamed(Routes.editBackupPassword));

  @override
  Widget body(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
            child: Container(
                padding: EdgeInsets.only(left: 20, right: 20),
                height: 300,
                child: Column(children: [
                  Text(
                    'Backup password:',
                    style: TextStyle(fontSize: 30),
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 10),
                      child: Observer(
                          builder: (_) => GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                      text:
                                          backupViewModelBase.backupPassword));
                                  showBar<void>(
                                      context,
                                      S.of(context).transaction_details_copied(
                                          'Backup password'));
                                },
                                child: Text(
                                  backupViewModelBase.backupPassword,
                                  style: TextStyle(fontSize: 26),
                                  textAlign: TextAlign.center,
                                ),
                              ))),
                  Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Please write down your Backup Password. Backup Password uses for import of backup files.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ))
                ]))),
        Positioned(
          child: Observer(
              builder: (_) => LoadingPrimaryButton(
                  isLoading: backupViewModelBase.state is IsExecutingState,
                  onPressed: () => onExportBackup(context),
                  text: 'Export backup',
                  color: Theme.of(context).accentTextTheme.body2.color,
                  textColor: Colors.white)),
          bottom: 30,
          left: 20,
          right: 20,
        )
      ],
    );
  }

  void onExportBackup(BuildContext context) {
    showPopUp<void>(
        context: context,
        builder: (dialogContext) {
          return AlertWithTwoActions(
              alertTitle: 'Export backup',
              alertContent:
                  'Please be sure that you have saved your Backup Password.You will be no available to import backup files without Backup Password.\n\nHave you written it down?',
              rightButtonText: S.of(context).seed_alert_yes,
              leftButtonText: S.of(context).seed_alert_back,
              actionRightButton: () async {
                Navigator.of(dialogContext).pop();
                final backup = await backupViewModelBase.exportBackup();
                await Share.file(
                    'Backup file', backup.name, backup.content, 'text');
              },
              actionLeftButton: () => Navigator.of(dialogContext).pop());
        });
  }
}
