

import "package:cw_core/exceptions/cake_exception.dart";
import "package:permission_handler/permission_handler.dart";

class SystemPermissionException extends CakeException {

  const SystemPermissionException(this.permission, super.message);
  final Permission permission;
}