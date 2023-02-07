import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mailer/flutter_mailer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExceptionHandler {
  static bool _hasError = false;

  static void _saveException(String? error, StackTrace? stackTrace) async {
    final appDocDir = await getApplicationDocumentsDirectory();

    final file = File('${appDocDir.path}/error.txt');
    final exception = {
      "${DateTime.now()}": {
        "Error": error,
        "StackTrace": stackTrace.toString(),
      }
    };

    const String separator = '''\n\n==========================================================
      ==========================================================\n\n''';

    await file.writeAsString(
      jsonEncode(exception) + separator,
      mode: FileMode.append,
    );
  }

  static void _sendExceptionFile() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();

      final file = File('${appDocDir.path}/error.txt');

      final MailOptions mailOptions = MailOptions(
        subject: 'Mobile App Issue',
        recipients: ['support@cakewallet.com'],
        attachments: [file.path],
      );

      final result = await FlutterMailer.send(mailOptions);

      // Clear file content if the error was sent or saved.
      // On android we can't know if it was sent or saved
      if (result.name == MailerResponse.sent.name ||
          result.name == MailerResponse.saved.name ||
          result.name == MailerResponse.android.name) {
        file.writeAsString("", mode: FileMode.write);
      }
    } catch (e, s) {
      _saveException(e.toString(), s);
    }
  }

  static void onError(FlutterErrorDetails errorDetails) async {
    if (kDebugMode) {
      FlutterError.presentError(errorDetails);
      return;
    }

    if (_ignoreError(errorDetails.exception.toString())) {
      return;
    }

    _saveException(errorDetails.exception.toString(), errorDetails.stack);

    final sharedPrefs = await SharedPreferences.getInstance();

    final lastPopupDate =
        DateTime.tryParse(sharedPrefs.getString(PreferencesKey.lastPopupDate) ?? '') ??
            DateTime.parse("2001-01-01");

    final durationSinceLastReport = DateTime.now().difference(lastPopupDate).inDays;

    // cool-down duration to be 7 days between reports
    if (_hasError || durationSinceLastReport < 7) {
      return;
    }
    _hasError = true;

    sharedPrefs.setString(PreferencesKey.lastPopupDate, DateTime.now().toString());

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        await showPopUp<void>(
          context: navigatorKey.currentContext!,
          builder: (context) {
            return AlertWithTwoActions(
              isDividerExist: true,
              alertTitle: S.of(context).error,
              alertContent: S.of(context).error_dialog_content,
              rightButtonText: S.of(context).send,
              leftButtonText: S.of(context).do_not_send,
              actionRightButton: () {
                Navigator.of(context).pop();
                _sendExceptionFile();
              },
              actionLeftButton: () {
                Navigator.of(context).pop();
              },
            );
          },
        );

        _hasError = false;
      },
    );
  }

  /// Ignore User related errors or system errors
  static bool _ignoreError(String error) {
    return error.contains("errno = 103") || // SocketException: Software caused connection abort
        error.contains("errno = 9") || // SocketException: Bad file descriptor
        error.contains("errno = 54"); // SocketException: Connection reset by peer
  }
}
