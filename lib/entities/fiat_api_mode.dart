import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/enumerable_item.dart';

class FiatApiMode extends EnumerableItem<int> with Serializable<int> {
  const FiatApiMode({required String title, required int raw}) : super(title: title, raw: raw);

  static const all = [FiatApiMode.enabled, FiatApiMode.torOnly, FiatApiMode.disabled];

  static const enabled = FiatApiMode(raw: 0, title: 'Enabled');
  static const torOnly = FiatApiMode(raw: 1, title: 'Tor only');
  static const disabled = FiatApiMode(raw: 2, title: 'Disabled');

  static FiatApiMode deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return enabled;
      case 1:
        return torOnly;
      case 2:
        return disabled;
      default:
        throw Exception('Unexpected token: $raw for FiatApiMode deserialize');
    }
  }

  @override
  String toString() {
    switch (this) {
      case FiatApiMode.enabled:
        return S.current.enabled;
      case FiatApiMode.torOnly:
        return S.current.tor_only;
      case FiatApiMode.disabled:
        return S.current.disabled;
      default:
        return '';
    }
  }
}
