import 'package:flutter/foundation.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/enumerable_item.dart';

class BalanceDisplayMode extends EnumerableItem<int> with Serializable<int> {
  const BalanceDisplayMode({required String title, required int raw})
      : super(title: title, raw: raw);

  static const all = [
    BalanceDisplayMode.hiddenBalance,
    BalanceDisplayMode.displayableBalance,
  ];
  static const fullBalance = BalanceDisplayMode(raw: 0, title: 'Full Balance');
  static const availableBalance =
      BalanceDisplayMode(raw: 1, title: 'Available Balance');
  static const hiddenBalance =
      BalanceDisplayMode(raw: 2, title: 'Hidden Balance');
  static const displayableBalance =
      BalanceDisplayMode(raw: 3, title: 'Displayable Balance');

  static BalanceDisplayMode deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return fullBalance;
      case 1:
        return availableBalance;
      case 2:
        return hiddenBalance;
      case 3:
        return displayableBalance;
      default:
        throw Exception('Unexpected token: $raw for BalanceDisplayMode deserialize');
    }
  }

  @override
  String toString() {
    switch (this) {
      case BalanceDisplayMode.fullBalance:
        return S.current.xmr_full_balance;
      case BalanceDisplayMode.availableBalance:
        return S.current.xmr_available_balance;
      case BalanceDisplayMode.hiddenBalance:
        return S.current.xmr_hidden;
      case BalanceDisplayMode.displayableBalance:
        return S.current.displayable;
      default:
        return '';
    }
  }
}
