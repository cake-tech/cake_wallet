import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/evm_call_data_transaction_credentials.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'pegaroute_trade_record.dart';
import 'pegaroute_trade_store.dart';

/// Each return value is a separately confirmed Cake transaction. The same order
/// row owns its claim/receipt; reset and approval hashes are never Trade.txId.
Future<({PendingTransaction pending, String step, String description, String to, String data})?>
    preparePegarouteApproval({required WalletBase wallet, required Trade trade,
    required PegarouteTradeStore store, required TransactionPriority? priority,
    required void Function() checkContext}) async {
  var current = await store.latest(trade);
  checkContext();
  PegarouteTradeStore.eligible(current);
  var record = PegarouteTradeRecord.read(current);
  final approval = record.execution.approval;
  if (approval == null) return null;
  if (evm == null) throw StateError('EVM wallet is unavailable');

  for (final entry in record.approvals.entries) {
    final evidence = entry.value as Map;
    if (evidence['state'] == 'failed') {
      throw StateError('Approval failed on-chain. This order has not been funded.');
    }
    if (evidence['state'] == 'confirmed') continue;
    bool? receipt;
    try {
      receipt = await evm!.getTransactionReceipt(wallet, evidence['hash'] as String)
          .timeout(const Duration(seconds: 6));
    } catch (_) { /* Unavailable receipt is pending, not permission to resend. */ }
    checkContext();
    if (receipt == null) {
      throw StateError('Approval confirmation is pending. Check this order again; do not resend approval.');
    }
    current = await store.approvalProgress(current, entry.key, evidence['id'] as String,
        evidence['hash'] as String, receipt ? 'confirmed' : 'failed');
    checkContext();
    if (!receipt) throw StateError('Approval failed on-chain. This order has not been funded.');
  }

  final allowance = await evm!.getAllowance(wallet, approval.tokenAddress, approval.spender)
      .timeout(const Duration(seconds: 6));
  checkContext();
  current = await store.latest(current);
  checkContext();
  PegarouteTradeStore.eligible(current);
  record = PegarouteTradeRecord.read(current);
  final requiredAmount = record.sourceUnits(current.amount);
  if (allowance == null) throw StateError('Token allowance is unavailable');
  if (requiredAmount <= BigInt.zero || requiredAmount.bitLength > 256) {
    throw StateError('Unsupported approval amount');
  }
  if (allowance >= requiredAmount) return null;
  if (record.approvals.containsKey('approve')) {
    throw StateError('The confirmed approval no longer covers this order. No funding was submitted.');
  }
  final reset = wallet.chainId == 1 &&
      approval.tokenAddress.toLowerCase() == '0xdac17f958d2ee523a2206206994597c13d831ec7' &&
      allowance > BigInt.zero;
  if (reset && record.approvals.containsKey('reset')) {
    throw StateError('Token allowance changed after its reset');
  }
  final step = reset ? 'reset' : 'approve';
  final units = reset ? BigInt.zero : requiredAmount;
  final data = '0x095ea7b3${approval.spender.substring(2).toLowerCase().padLeft(64, '0')}'
      '${units.toRadixString(16).padLeft(64, '0')}';
  // Address the reviewed token contract directly. A symbol-based facade lookup
  // can choose a different same-symbol token in a wallet's custom token list.
  final pending = await wallet.createTransaction(EvmCallDataTransactionCredentials(
      to: approval.tokenAddress, data: data, value: Money.zero(PegarouteTradeRecord.currency(record.source)),
      priority: priority, gasLimit: 65000, useBlinkProtection: false));
  checkContext();
  PegarouteTradeStore.eligible(await store.latest(current));
  checkContext();
  return (pending: pending, step: step, to: approval.tokenAddress, data: data,
      description: reset ? 'Reset ${current.from!.title} allowance to 0'
          : 'Approve ${current.amount} ${current.from!.title}');
}

Future<void> requirePegarouteAllowance(WalletBase wallet, PegarouteTradeRecord record,
    void Function() checkContext) async {
  final approval = record.execution.approval;
  if (approval == null) return;
  final allowance = await evm!.getAllowance(wallet, approval.tokenAddress, approval.spender)
      .timeout(const Duration(seconds: 6));
  checkContext();
  if (allowance == null || allowance < BigInt.parse(approval.amount.baseUnits)) {
    throw StateError('Token allowance no longer covers this order. No funding was submitted.');
  }
}
