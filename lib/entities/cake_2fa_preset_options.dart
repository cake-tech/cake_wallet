import 'package:cw_core/enumerable_item.dart';
import "package:cw_core/exceptions/cake_exception.dart";

class Cake2FAPresetsOptions extends EnumerableItem<int> with Serializable<int> {
  const Cake2FAPresetsOptions({required String super.title, required int super.raw});

  static const normal = Cake2FAPresetsOptions(title: 'Normal', raw: 1);
  static const strict = Cake2FAPresetsOptions(title: 'Strict', raw: 2);
  static const custom = Cake2FAPresetsOptions(title: 'Custom', raw: 3);

  static Cake2FAPresetsOptions deserialize({required int raw}) {
    switch (raw) {
      case 0:
      case 1:
        return Cake2FAPresetsOptions.normal;
      case 2:
        return Cake2FAPresetsOptions.strict;
      case 3:
        return Cake2FAPresetsOptions.custom;
      default:
        throw DeserializeException(
          'Incorrect Cake 2FA Preset $raw  for Cake2FAPresetOptions deserialize',
        );
    }
  }
}

enum VerboseControlSettings {
  accessWallet,
  addingContacts,
  sendsToContacts,
  sendsToNonContacts,
  sendsToInternalWallets,
  exchangesToInternalWallets,
  exchangesToExternalWallets,
  securityAndBackupSettings,
  creatingNewWallets,
}
