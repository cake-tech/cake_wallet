

import "package:cw_core/exceptions/cake_exception.dart";

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