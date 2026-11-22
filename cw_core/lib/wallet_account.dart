import "package:cw_core/balance.dart";

abstract class WalletAccount<B extends Balance> {
  int get index;
  String get label;
  B get balance;
}
