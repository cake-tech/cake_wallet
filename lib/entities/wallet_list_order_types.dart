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
        return "Creation date";// TODO: CW-512 localize this
      case WalletListOrderType.Alphabetical:
        return "Alphabetical";
      case WalletListOrderType.GroupByType:
        return "Group by type";
      case WalletListOrderType.Custom:
        return "Custom";
    }
  }
}
