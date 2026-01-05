import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_zcash/cw_zcash.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:warp_api/warp_api.dart';

class PendingZcashTransaction with PendingTransaction {
  PendingZcashTransaction({required this.zcashWallet, required this.credentials, required this.txPlan});

  final ZcashWallet zcashWallet;
  final ZcashTransactionCredentials credentials;
  final String txPlan;
  String? _txId;

  @override
  String get id => _txId ?? '';

  @override
  String get hex => '';

  @override
  String get amountFormatted {
    final totalAmount = credentials.outputs.fold<int>(
      0,
      (final sum, final output) => sum + (output.formattedCryptoAmount ?? 0),
    );
    return '${walletTypeToCryptoCurrency(WalletType.zcash).formatAmount(BigInt.from(totalAmount))} ${walletTypeToCryptoCurrency(WalletType.zcash).title}';
  }

  @override
  String get feeFormatted => '0 ${walletTypeToCryptoCurrency(WalletType.zcash).title}';

  @override
  String get feeFormattedValue => '0';

  @override
  Future<void> commit() async {
    printV("commit(): $txPlan");
    _txId = await ZcashWalletService.runInDbMutex(
      () => WarpApi.signAndBroadcast(ZcashWalletBase.coin, zcashWallet.accountId, txPlan),
    );
    await zcashWallet.updateTransactions();
    await zcashWallet.updateBalance();
  }

  @override
  Future<Map<String, String>> commitUR() {
    throw UnimplementedError('UR not supported for Zcash');
  }

  @override
  bool shouldCommitUR() => false;
}
