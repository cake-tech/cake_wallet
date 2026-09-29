import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'pegaroute_capability_gate.dart';
import 'pegaroute_currency_mapper.dart';

/// Select an exact input before quoting. This does not authorize a payment.
Future<Money> pegarouteMaxAmount(WalletBase wallet, Money balance,
    TransactionPriority? priority) async {
  const mapper = PegarouteCurrencyMapper();
  final currency = balance.currency as CryptoCurrency;
  final asset = mapper.map(currency);
  if (asset.token != asset.nativeToken) return balance;
  if (priority == null) throw StateError('Fee priority is unavailable');

  final Money amount;
  if (PegarouteCapabilityGate.evmChains.containsKey(asset.chain)) {
    await wallet.updateEstimatedFeesParams(priority);
    final fee = BigInt.tryParse(evm?.getEVMNativeEstimatedFee(wallet) ?? '');
    if (fee == null || fee <= BigInt.zero) throw StateError('Fee estimate is unavailable');
    amount = balance.copyWith(amount: balance.amount - fee);
  } else if (PegarouteCapabilityGate.utxo.contains(asset.chain)) {
    amount = await bitcoin!.estimateFakeSendAllTxAmount(wallet, priority,
        coinTypeToSpendFrom: wallet.type == WalletType.litecoin
            ? UnspentCoinType.nonMweb : UnspentCoinType.any);
  } else {
    throw StateError('Native Max is unavailable for this wallet');
  }
  if (amount.currency is! CryptoCurrency ||
      !mapper.matchesCanonicalTuple(amount.currency as CryptoCurrency, asset) ||
      (amount.currency as CryptoCurrency).decimals != currency.decimals ||
      amount.amount <= BigInt.zero || amount.amount >= balance.amount) {
    throw StateError('No spendable amount after the fee reserve');
  }
  return amount;
}
