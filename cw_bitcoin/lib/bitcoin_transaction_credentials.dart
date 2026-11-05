import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/unspent_coin_type.dart';

class BitcoinTransactionCredentials {
  BitcoinTransactionCredentials(
    this.outputs, {
    required this.priority,
    this.feeRate,
    this.coinTypeToSpendFrom = UnspentCoinType.any,
    this.payjoinUri,
    this.currency,
  });

  final List<OutputInfo> outputs;
  final BitcoinTransactionPriority? priority;
  final int? feeRate;
  final UnspentCoinType coinTypeToSpendFrom;
  final String? payjoinUri;

  /// The asset being sent. Null (or the wallet's native currency) means BTC/Lightning.
  /// A [SparkToken] here means the payment goes through `LightningWallet` (the Breez SDK side)
  /// as a Spark token transfer.
  final CryptoCurrency? currency;
}
