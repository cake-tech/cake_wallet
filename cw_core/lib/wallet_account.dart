import "package:cw_core/balance.dart";

abstract class WalletAccount<B extends Balance> {
  int get index;
  String get label;
  B get balance;
}

class SingleWalletAccount<B extends Balance> implements WalletAccount<B> {
  SingleWalletAccount({required this.label, required B Function() balance})
      : _balance = balance;

  final B Function() _balance;

  @override
  int get index => 0;

  @override
  final String label;

  @override
  B get balance => _balance();
}
