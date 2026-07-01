import 'package:cw_core/enumerable_item.dart';

class Cake2FAPresetsOptions extends EnumerableItem<int> with Serializable<int> {
  const Cake2FAPresetsOptions({required String super.title, required int super.raw});

  static const narrow = Cake2FAPresetsOptions(title: 'Narrow', raw: 0);
  static const normal = Cake2FAPresetsOptions(title: 'Normal', raw: 1);
  static const aggressive = Cake2FAPresetsOptions(title: 'Aggressive', raw: 2);
  static const none = Cake2FAPresetsOptions(title: 'None', raw: 3);

  static Cake2FAPresetsOptions deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return Cake2FAPresetsOptions.narrow;
      case 1:
        return Cake2FAPresetsOptions.normal;
      case 2:
        return Cake2FAPresetsOptions.aggressive;
      case 3:
        return Cake2FAPresetsOptions.none;
      default:
        throw Exception(
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
