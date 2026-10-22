import "package:cw_core/wallet_account.dart";
import "package:cw_wownero/wownero_balance.dart";

class WowneroWalletAccount implements WalletAccount<WowneroBalance> {
  WowneroWalletAccount({
    required this.index,
    required this.label,
    required WowneroBalance Function() balance,
  }) : _balance = balance;

  final WowneroBalance Function() _balance;

  @override
  final int index;

  @override
  final String label;

  @override
  WowneroBalance get balance => _balance();
}
