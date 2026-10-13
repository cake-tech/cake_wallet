import "package:cw_core/amount/money.dart";

class AccountListItem {
  AccountListItem({
    required this.label,
    required this.id,
    required this.balance,
    this.isSelected = false,
  });

  final String label;
  final int id;
  final bool isSelected;
  final Money balance;

  bool get isFunded => balance.sign > 0;
}
