import 'package:cake_wallet/generated/i18n.dart';

enum WalletListOrderType {
  CreationDate,
  Alphabetical,
  GroupByType,
  Custom;

  @override
  String toString() {
    switch (this) {
      case WalletListOrderType.CreationDate:
        return S.current.creation_date;
      case WalletListOrderType.Alphabetical:
        return S.current.alphabetical;
      case WalletListOrderType.GroupByType:
        return S.current.group_by_type;
      case WalletListOrderType.Custom:
        return S.current.custom_drag;
    }
  }
}
