import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cake_wallet/generated/i18n.dart';

class PermissionHandler {
  static final Map<Permission, String> _permissionMessages = {
    Permission.camera: "Camera permission is required. \nPlease enable it from app settings.",
  };

  static Future<bool> checkPermission(Permission permission,BuildContext context) async {
    var status = await permission.status;

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
