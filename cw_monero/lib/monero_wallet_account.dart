import "package:cw_core/wallet_account.dart";
import "package:cw_monero/monero_balance.dart";

class MoneroWalletAccount implements WalletAccount<MoneroBalance> {
  MoneroWalletAccount({
    required this.index,
    required this.label,
    required MoneroBalance Function() balance,
  }) : _balance = balance;

  final MoneroBalance Function() _balance;

  @override
  final int index;

  @override
  final String label;

  @override
  MoneroBalance get balance => _balance();
}
