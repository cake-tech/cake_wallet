import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/provider/pegaroute_exchange_provider.dart';
import 'package:cw_core/wallet_base.dart';
import 'pegaroute_trade_record.dart';
import 'pegaroute_trade_store.dart';

enum PegaroutePreparationRetryAction { retryPreparation, checkApproval, continuePreparation }

/// Re-enter preparation only. A missing funding hash is never retry authority:
/// reload the order's durable funding and separate approval claims first.
Future<PegaroutePreparationRetryAction?> pegaroutePreparationRetryAction({
  required Trade trade, required WalletBase wallet, PegarouteTradeStore? store,
}) async {
  final captured = PegarouteTradeRecord.fromSqliteRow(trade.toSqliteMap());
  final current = await (store ?? PegarouteTradeStore()).latest(captured);
  PegarouteTradeStore.same(captured, trade);
  PegarouteTradeStore.eligible(current);
  final record = PegarouteTradeRecord.read(current);
  if (current.walletId != wallet.id || current.fromWalletAddress != wallet.walletAddresses.address ||
      current.chainId != wallet.chainId || !PegaRouteExchangeProvider.supportsWallet(wallet, current.from!)) {
    return null;
  }
  if (record.approvals.isEmpty) return PegaroutePreparationRetryAction.retryPreparation;
  if (record.approvals.values.any((value) => (value as Map)['state'] == 'failed')) return null;
  if (record.approvals.values.any((value) => (value as Map)['state'] != 'confirmed')) {
    return PegaroutePreparationRetryAction.checkApproval;
  }
  return PegaroutePreparationRetryAction.continuePreparation;
}
