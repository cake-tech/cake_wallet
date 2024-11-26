import 'dart:io';

import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/root_dir.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mailer/flutter_mailer.dart';
import 'package:cake_wallet/utils/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExceptionHandler {
  static bool _hasError = false;
  static const _coolDownDurationInDays = 7;
  static File? _file;

  static Future<void> _saveException(String? error, StackTrace? stackTrace, {String? library}) async {
    final appDocDir = await getAppDir();

    if (_file == null) {
      _file = File('${appDocDir.path}/error.txt');
    }

    final exception = {
      "${DateTime.now()}": {
        "Error": "$error\n\n",
        "Library": "$library\n\n",
        "StackTrace": stackTrace.toString(),
      }
    };

    const String separator = '''\n\n==========================================================
      ==========================================================\n\n''';

    /// don't save existing errors
    if (_file!.existsSync()) {
      final String fileContent = await _file!.readAsString();
      if (fileContent.contains("${exception.values.first}")) {
        return;
      }
    }

    _file!.writeAsStringSync(
      "$exception $separator",
      mode: FileMode.append,
    );
  }

  static void _sendExceptionFile() async {
    try {
      if (_file == null) {
        final appDocDir = await getAppDir();

        _file = File('${appDocDir.path}/error.txt');
      }

      await _addDeviceInfo(_file!);

      // Check if a mail client is available
      final bool canSend = await FlutterMailer.canSendMail();

      if (Platform.isIOS && !canSend) {
        debugPrint('Mail app is not available');
        return;
      }

      final MailOptions mailOptions = MailOptions(
        subject: 'Mobile App Issue',
        recipients: ['support@cakewallet.com'],
        attachments: [_file!.path],
      );

      final result = await FlutterMailer.send(mailOptions);

      // Clear file content if the error was sent or saved.
      // On android we can't know if it was sent or saved
      if (result.name == MailerResponse.sent.name ||
          result.name == MailerResponse.saved.name ||
          result.name == MailerResponse.android.name) {
        _file!.writeAsString("", mode: FileMode.write);
      }
    } catch (e, s) {
      _saveException(e.toString(), s);
    }
  }

  static Future<void> resetLastPopupDate() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setString(PreferencesKey.lastPopupDate, DateTime(1971).toString());
  }

  static Future<void> onError(FlutterErrorDetails errorDetails) async {
    if (kDebugMode || kProfileMode) {
      FlutterError.presentError(errorDetails);
      debugPrint(errorDetails.toString());
      return;
    }

    if (_ignoreError(errorDetails.exception.toString())) {
      return;
    }

    _saveException(
      errorDetails.exceptionAsString(),
      errorDetails.stack,
      library: errorDetails.library,
    );

    if (errorDetails.silent) {
      return;
    }

    final sharedPrefs = await SharedPreferences.getInstance();

    final lastPopupDate =
        DateTime.tryParse(sharedPrefs.getString(PreferencesKey.lastPopupDate) ?? '') ??
            DateTime.now().subtract(Duration(days: _coolDownDurationInDays + 1));

    final durationSinceLastReport = DateTime.now().difference(lastPopupDate).inDays;

    if (_hasError || durationSinceLastReport < _coolDownDurationInDays) {
      return;
    }
    _hasError = true;

    await sharedPrefs.setString(PreferencesKey.lastPopupDate, DateTime.now().toString());

    // Instead of using WidgetsBinding.instance.addPostFrameCallback we
    // await Future.delayed(Duration.zero), which does essentially the same (
    // but doesn't wait for actual frame to be rendered), but it allows us to
    // properly await the execution - which is what we want, without awaiting
    // other code may call functions like Navigator.pop(), and close the alert
    // instead of the intended UI.
    // WidgetsBinding.instance.addPostFrameCallback(
    //   (timeStamp) async {
    await Future.delayed(Duration.zero);
    if (navigatorKey.currentContext != null) {
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
    }

    _hasError = false;
  }

  /// Ignore User related errors or system errors
  static bool _ignoreError(String error) =>
      _ignoredErrors.any((element) => error.contains(element));

  static const List<String> _ignoredErrors = const [
    "Bad file descriptor",
    "No space left on device",
    "OS Error: Broken pipe",
    "Can't assign requested address",
    "OS Error: Socket is not connected",
    "Operation timed out",
    "No route to host",
    "Software caused connection abort",
    "Connection reset by peer",
    "Connection timed out",
    "Connection reset by peer",
    "Connection closed before full header was received",
    "Connection terminated during handshake",
    "PERMISSION_NOT_GRANTED",
    "Failed host lookup:",
    "CERTIFICATE_VERIFY_FAILED",
    "Handshake error in client",
    "Error while launching http",
    "OS Error: Network is unreachable",
    "ClientException: Write failed, uri=http",
    "Corrupted wallets seeds",
    "bad_alloc",
    "does not correspond",
    "basic_string",
    "input_stream",
    "input stream error",
    "invalid signature",
    "invalid password",
  ];

  static Future<void> _addDeviceInfo(File file) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceInfo = {};

    if (Platform.isAndroid) {
      deviceInfo = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      deviceInfo["Platform"] = "Android";
    } else if (Platform.isIOS) {
      deviceInfo = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      deviceInfo["Platform"] = "iOS";
    } else if (Platform.isLinux) {
      deviceInfo = _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo);
      deviceInfo["Platform"] = "Linux";
    } else if (Platform.isMacOS) {
      deviceInfo = _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo);
      deviceInfo["Platform"] = "MacOS";
    } else if (Platform.isWindows) {
      deviceInfo = _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo);
      deviceInfo["Platform"] = "Windows";
    }

    await file.writeAsString(
      "App Version: $currentVersion\n\nDevice Info $deviceInfo\n\n",
      mode: FileMode.append,
    );
  }

  static Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'brand': build.brand,
      'device': build.device,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
    };
  }

  static Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'isPhysicalDevice': data.isPhysicalDevice,
    };
  }

  static Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'version': data.version,
      'versionCodename': data.versionCodename,
      'versionId': data.versionId,
      'prettyName': data.prettyName,
      'buildId': data.buildId,
      'variant': data.variant,
      'variantId': data.variantId,
    };
  }

  static Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo data) {
    return <String, dynamic>{
      'arch': data.arch,
      'model': data.model,
      'kernelVersion': data.kernelVersion,
      'osRelease': data.osRelease,
    };
  }

  static Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo data) {
    return <String, dynamic>{
      'majorVersion': data.majorVersion,
      'minorVersion': data.minorVersion,
      'buildNumber': data.buildNumber,
      'productType': data.productType,
      'productName': data.productName,
    };
  }

  static Future<void> showError(String error, {int? delayInSeconds}) async {
    if (_hasError) {
      return;
    }
    _hasError = true;
    if (delayInSeconds != null) {
      Future.delayed(Duration(seconds: delayInSeconds), () => _showCopyPopup(error));
      return;
    }

    await Future.delayed(Duration.zero);
    await _showCopyPopup(error);
  }

  static Future<void> _showCopyPopup(String content) async {
    if (navigatorKey.currentContext != null) {
      final shouldCopy = await showPopUp<bool?>(
        context: navigatorKey.currentContext!,
        builder: (context) {
          return AlertWithTwoActions(
            isDividerExist: true,
            alertTitle: S.of(context).error,
            alertContent: content,
            rightButtonText: S.of(context).copy,
            leftButtonText: S.of(context).close,
            actionRightButton: () {
              Navigator.of(context).pop(true);
            },
            actionLeftButton: () {
              Navigator.of(context).pop();
            },
          );
        },
      );

      if (shouldCopy == true) {
        await Clipboard.setData(ClipboardData(text: content));
        await showBar<void>(
          navigatorKey.currentContext!,
          S.of(navigatorKey.currentContext!).copied_to_clipboard,
        );
      }
    }

    _hasError = false;
  }
}
