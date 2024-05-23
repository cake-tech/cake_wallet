import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/enumerable_item.dart';

class AutomaticBackupMode extends EnumerableItem<int> with Serializable<int> {
  const AutomaticBackupMode({required String title, required int raw})
      : super(title: title, raw: raw);

  static const all = [
    AutomaticBackupMode.disabled,
    AutomaticBackupMode.minutely,
    AutomaticBackupMode.weekly,
    AutomaticBackupMode.daily
  ];

  static const disabled = AutomaticBackupMode(raw: 0, title: 'Disabled');
  static const weekly = AutomaticBackupMode(raw: 1, title: 'Weekly');
  static const daily = AutomaticBackupMode(raw: 2, title: 'Daily');
  static const minutely = AutomaticBackupMode(raw: 3, title: 'Minutely');

  static AutomaticBackupMode deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return disabled;
      case 1:
        return weekly;
      case 2:
        return daily;
      case 3:
        return minutely;
      default:
        throw Exception('Unexpected token: $raw for AutomaticBackupMode deserialize');
    }
  }

  @override
  String toString() {
    switch (this) {
      case AutomaticBackupMode.disabled:
        return S.current.disabled;
      case AutomaticBackupMode.weekly:
        return S.current.weekly;
      case AutomaticBackupMode.daily:
        return S.current.daily;
      case AutomaticBackupMode.minutely:
        return "TESTING";
      default:
        return '';
    }
  }
}
