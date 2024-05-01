import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/enumerable_item.dart';

class AlertFrequency extends EnumerableItem<int> with Serializable<int> {
  const AlertFrequency({required String title, required int raw})
      : super(title: title, raw: raw);

  static const all = [
    AlertFrequency.daily,
    AlertFrequency.weekly,
    AlertFrequency.monthly
  ];

  static const daily = AlertFrequency(raw: 0, title: 'Daily');
  static const weekly = AlertFrequency(raw: 1, title: 'Weekly');
  static const monthly = AlertFrequency(raw: 2, title: 'Monthly');

  static AlertFrequency deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return daily;
      case 1:
        return weekly;
      case 2:
        return monthly;
      default:
        throw Exception('Unexpected token: $raw for AlertFrequency deserialize');
    }
  }

  @override
  String toString() {
    switch (this) {
      case AlertFrequency.daily:
        return S.current.daily;
      case AlertFrequency.weekly:
        return S.current.weekly;
      case AlertFrequency.monthly:
        return S.current.monthly;
      default:
        return '';
    }
  }
}
