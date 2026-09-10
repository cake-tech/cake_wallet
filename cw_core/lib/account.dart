import "package:cw_core/amount/money.dart";

class Account {
  const Account({required this.id, required this.label, this.balance});

  final int id;
  final String label;
  final Money? balance;
}
