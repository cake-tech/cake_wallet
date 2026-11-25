

import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/utils/print_verbose.dart";

class WalletLockedException extends CakeException {
  const WalletLockedException() : super("Zcash wallet locked! Please contact support");
}

class UpdateException extends CakeException {
  const UpdateException(super.message);
}

class ZcashAccountException extends CakeException {
  const ZcashAccountException(super.message);
}

class AddressRotationException extends CakeException {
  const AddressRotationException(super.message);
}

class MigrationException extends CakeException {
  const MigrationException(super.message);
}

Future<T> withCompactRustErrors<T>(
  final Future<T> Function() body,
  final CakeException Function(String message) wrap,
) async {
  try {
    return await body();
  } catch (e, s) {
    if (!e.toString().contains("Stack backtrace:")) {
      rethrow;
    }
    printV(e);
    Error.throwWithStackTrace(wrap(e.toString().split("Stack backtrace:").first.trim()), s);
  }
}
