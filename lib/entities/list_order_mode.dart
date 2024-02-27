import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/enumerable_item.dart';

class ListOrderMode extends EnumerableItem<int> with Serializable<int> {
  const ListOrderMode({required String title, required int raw}) : super(title: title, raw: raw);

  static const all = [ListOrderMode.ascending, ListOrderMode.descending];

  static const ascending = ListOrderMode(raw: 0, title: 'Ascending');
  static const descending = ListOrderMode(raw: 1, title: 'Descending');

  static ListOrderMode deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return ascending;
      case 1:
        return descending;
      default:
        throw Exception('Unexpected token: $raw for ListOrderMode deserialize');
    }
  }

  @override
  String toString() {
    switch (this) {
      case ListOrderMode.ascending:
        return S.current.ascending;
      case ListOrderMode.descending:
        return S.current.descending;
      default:
        return '';
    }
  }
}
