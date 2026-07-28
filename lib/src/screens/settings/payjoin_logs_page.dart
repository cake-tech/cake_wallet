import 'dart:io';

import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/settings/payjoin_settings_view_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class PayjoinLogPage extends BasePage {
  PayjoinLogPage(this._payjoinSettingsViewModel);

  final PayjoinSettingsViewModel _payjoinSettingsViewModel;

  @override
  String get title => S.current.payjoin_logs;

  @override
  Widget body(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<String>(
          future: _payjoinSettingsViewModel.getAbbreviatedLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(S.of(context).no_payjoin_logs_found));
            } else {
              return SingleChildScrollView(
                controller: ModalScrollController.of(context),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    snapshot.data!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontFamily: 'Monospace'),
                  ),
                ),
              );
            }
          },
        ),
        Positioned(
          child: LoadingPrimaryButton(
            onPressed: () => onExportLogs(context),
            text: S.of(context).export_logs,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
          ),
          bottom: 24,
          left: 24,
          right: 24,
        )
      ],
    );
  }

  void onExportLogs(BuildContext context) {
    if (Platform.isAndroid) {
      onExportAndroid(context);
    } else if (Platform.isIOS) {
      share(context);
    } else {
      _saveFile();
    }
  }

  void onExportAndroid(BuildContext context) {
    showPopUp<void>(
        context: context,
        builder: (dialogContext) {
          return AlertWithTwoActions(
              alertTitle: S.of(context).export_backup,
              alertContent: S.of(context).select_destination,
              rightButtonText: S.of(context).save,
              leftButtonText: S.of(context).cancel,
              actionLeftButton: () async {
                Navigator.of(dialogContext).pop();
              },
              actionRightButton: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await share(context);
                } catch (e, s) {
                  ExceptionHandler.onError(FlutterErrorDetails(
                    exception: e,
                    stack: s,
                    library: 'Export Payjoin Logs',
                  ));
                }
              });
        });
  }

  Future<void> share(BuildContext context) async {
    final file = await _payjoinSettingsViewModel.getPayjoinLogFile();
    await ShareUtil.shareFile(
        filePath: file.path, fileName: 'Payjoin_export.txt', context: context);
  }

  Future<void> _saveFile() async {
    try {
      final file = await _payjoinSettingsViewModel.getPayjoinLogFile();
      String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: S.current.save_your_file_to_desired_location,
          fileName: 'Payjoin_export.txt',
          lockParentWindow: true);

      if (outputFile == null) return;
      await file.copy(outputFile);
    } catch (exception, stackTrace) {
      ExceptionHandler.onError(FlutterErrorDetails(
        exception: exception,
        stack: stackTrace,
        library: 'Export Payjoin Logs',
      ));
    }
  }
}
