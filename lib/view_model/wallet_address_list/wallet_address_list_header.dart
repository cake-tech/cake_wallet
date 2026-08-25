import 'package:cake_wallet/utils/list_item.dart';

class WalletAddressListHeader extends ListItem {
  final String? title;

  /// If true, this header represents shielded addresses (e.g., PIVX Sapling).
  /// Used to determine what type of address to create when user taps "Add".
  final bool isShielded;

  /// Optional subtitle shown below the title (e.g., "All addresses share this balance").
  final String? subtitle;

  /// Optional balance to display in the header (for shielded pools).
  final String? balance;

  WalletAddressListHeader({
    this.title,
    this.isShielded = false,
    this.subtitle,
    this.balance,
  });
}
