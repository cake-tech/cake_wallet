import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/enumerable_item.dart';

class ExchangeApiMode extends EnumerableItem<int> with Serializable<int> {
  const ExchangeApiMode({required String title, required int raw}) : super(title: title, raw: raw);

  static const all = [ExchangeApiMode.enabled, ExchangeApiMode.torOnly, ExchangeApiMode.disabled];

  static const enabled = ExchangeApiMode(raw: 0, title: 'Enabled');
  static const torOnly = ExchangeApiMode(raw: 1, title: 'Tor only');
  static const disabled = ExchangeApiMode(raw: 2, title: 'Disabled');

  static ExchangeApiMode deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return enabled;
      case 1:
        return torOnly;
      case 2:
        return disabled;
      default:
        throw Exception('Unexpected token: $raw for ExchangeApiMode deserialize');
    }
  }

  @override
  String toString() {
    switch (this) {
      case ExchangeApiMode.enabled:
        return S.current.enabled;
      case ExchangeApiMode.torOnly:
        return S.current.tor_only;
      case ExchangeApiMode.disabled:
        return S.current.disabled;
      default:
        return '';
    }
  }
}