import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<bool> checkPermission(Permission permission, BuildContext context) async {
    if (Platform.isIOS) {
      return true;
    }
    final Map<Permission, String> _permissionMessages = {
      Permission.camera: S.of(context).camera_permission_is_required,
    };

    var status = await permission.status;

    if (status.isDenied) {
      try {
        status = await permission.request();
      } catch (_) {}
    }

    if (status.isPermanentlyDenied || status.isDenied) {
      String? message = _permissionMessages[permission];
      if (message != null) {
        showBar<void>(context, message);
      }
      return false;
    }

    if (status.isGranted) {
      return true;
    }

    return false;
  }
}
