import 'package:flutter/foundation.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/enumerable_item.dart';

class BalanceDisplayMode extends EnumerableItem<int> with Serializable<int> {
  const BalanceDisplayMode({@required String title, @required int raw})
      : super(title: title, raw: raw);

  static const all = [
    BalanceDisplayMode.fullBalance,
    BalanceDisplayMode.availableBalance,
    BalanceDisplayMode.hiddenBalance
  ];
  static const fullBalance = BalanceDisplayMode(raw: 0, title: 'Full Balance');
  static const availableBalance =
      BalanceDisplayMode(raw: 1, title: 'Available Balance');
  static const hiddenBalance =
      BalanceDisplayMode(raw: 2, title: 'Hidden Balance');

  static BalanceDisplayMode deserialize({int raw}) {
    switch (raw) {
      case 0:
        return fullBalance;
      case 1:
        return availableBalance;
      case 2:
        return hiddenBalance;
      default:
        return null;
    }
  }

  @override
  String toString() {
    switch (this) {
      case BalanceDisplayMode.fullBalance:
        return S.current.full_balance;
      case BalanceDisplayMode.availableBalance:
        return S.current.available_balance;
      case BalanceDisplayMode.hiddenBalance:
        return S.current.hidden_balance;
      default:
        return '';
    }
  }
}
