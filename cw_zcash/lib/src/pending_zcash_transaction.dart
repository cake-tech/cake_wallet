import 'package:cw_core/amount/money.dart';
import 'package:cw_core/exceptions.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_zcash/cw_zcash.dart';
import 'package:zkool/src/rust/api/pay.dart' as zkool_pay;
import 'package:zkool/src/rust/api/network.dart' as zkool_network;

class PendingZcashTransaction with PendingTransaction {
  PendingZcashTransaction({
    required this.zcashWallet,
    required this.amount,
    required this.txPlan,
    required this.fee,
    required this.availableBalance,
    this.signedTxPackage,
    this.isShieldingTx = false,
  });

  final ZcashWallet zcashWallet;
  final zkool_pay.PcztPackage txPlan;
  final zkool_pay.PcztPackage? signedTxPackage;
  String? _txId;
  final Money availableBalance;
  final bool isShieldingTx;

  @override
  String get id => _txId ?? '';

  @override
  String get hex => '';

  @override
  final Money amount;

  @override
  String get amountFormatted => amount.toString();

  @override
  final Money fee;

  @override
  Future<void> commit() async {
    await ZcashWalletBase.runWithCoin(
      accountId: zcashWallet.accountId,
      func: (coin) async {
        final signTx = signedTxPackage ?? await zkool_pay.signTransaction(pczt: txPlan, c: coin);
        final txBytes = await zkool_pay.extractTransaction(package: signTx);
        final currentHeight = await zkool_network.getCurrentHeight(c: coin);
        final result = await zkool_pay.broadcastTransaction(
          height: currentHeight,
          txBytes: txBytes,
          c: coin,
        );
        printV("result: $result");
        final txId = ZcashWalletService.normalizeTxId(result);
        if (txId.length != 64) {
          throw TransactionCommitFailed(errorMessage: result);
        }
        _txId = txId;
        if (isShieldingTx) {
          await ZcashWalletService.addShieldedTx(txId);
        } else {
          zcashWallet.rememberPendingOutgoingAmount(txId, amount);
        }
      },
    );

    await zcashWallet.updateTransactions();
    await zcashWallet.updateBalance(
        runAutoShield: !isShieldingTx, runIronwoodMigrate: !isShieldingTx);
  }

  @override
  Future<Map<String, String>> commitUR() => throw UnimplementedError('UR not supported for Zcash');

  @override
  bool shouldCommitUR() => false;
}
