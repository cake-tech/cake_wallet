import 'dart:io';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/clipboard_util.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/backup_view_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BackupPage extends BasePage {
  BackupPage(this.backupViewModelBase);

  final BackupViewModelBase backupViewModelBase;

  @override
  String get title => S.current.backup;

  @override
  Widget body(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.only(left: 24, right: 24),
            height: 300,
            child: Column(
              children: [
                Text(
                  S.of(context).backup_password + ':',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 10),
                  child: Observer(
                    builder: (_) => GestureDetector(
                      onTap: () {
                        ClipboardUtil.setSensitiveDataToClipboard(
                          ClipboardData(text: backupViewModelBase.backupPassword),
                        );
                        showBar<void>(
                          context,
                          S.of(context).transaction_details_copied(S.of(context).backup_password),
                        );
                      },
                      child: Text(
                        backupViewModelBase.backupPassword,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    S.of(context).write_down_backup_password,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        ),
        Positioned(
          child: Column(
            children: [
              PrimaryButton(
                onPressed: () => Navigator.of(context).pushNamed(Routes.editBackupPassword),
                text: S.of(context).change_password,
                color: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(height: 10),
              Observer(
                builder: (_) => LoadingPrimaryButton(
                  isLoading: backupViewModelBase.state is IsExecutingState,
                  onPressed: () => onExportBackup(context),
                  text: S.of(context).export_backup,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          bottom: 24,
          left: 24,
          right: 24,
        )
      ],
    );
  }

  void onExportBackup(BuildContext context) {
    showPopUp<void>(
      context: context,
      builder: (dialogContext) {
        return AlertWithTwoActions(
          alertTitle: S.of(context).export_backup,
          alertContent: S.of(context).save_backup_password,
          rightButtonText: S.of(context).seed_alert_yes,
          leftButtonText: S.of(context).seed_alert_back,
          actionRightButton: () async {
            Navigator.of(dialogContext).pop();
            final backup = await backupViewModelBase.exportBackup();

            if (backup == null) {
              return;
            }

            if (Platform.isAndroid) {
              onExportAndroid(context, backup);
            } else if (Platform.isIOS) {
              await share(backup, context);
            } else {
              await _saveFile(backup);
            }
          },
          actionLeftButton: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  void onExportAndroid(BuildContext context, BackupExportFile backup) {
    showPopUp<void>(
        context: context,
        builder: (dialogContext) {
          return AlertWithTwoActions(
              alertTitle: S.of(context).export_backup,
              alertContent: S.of(context).select_destination,
              rightButtonText: S.of(context).save_to_downloads,
              leftButtonText: S.of(context).share,
              actionRightButton: () async {
                await backupViewModelBase.saveToDownload(backup.name, backup.file);
                Navigator.of(dialogContext).pop();
                await showBar<void>(context, S.of(context).file_saved);
              },
              actionLeftButton: () async {
                Navigator.of(dialogContext).pop();
                await share(backup, context);
              });
        });
  }

  Future<void> share(BackupExportFile backup, BuildContext context) async {
    final path = await backupViewModelBase.saveBackupFileLocally(backup);
    await ShareUtil.shareFile(filePath: path, fileName: backup.name, context: context);
    await backupViewModelBase.removeBackupFileLocally(backup);
  }

  Future<void> _saveFile(BackupExportFile backup) async {
    String? outputFile = await FilePicker.platform
        .saveFile(dialogTitle: 'Save Your File to desired location', fileName: backup.name);

    try {
      await backup.file.copy(outputFile!);
    } catch (exception, stackTrace) {
      await ExceptionHandler.onError(FlutterErrorDetails(
        exception: exception,
        stack: stackTrace,
        library: "Export Backup",
      ));
    }
  }
}
