import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_ethereum/ethereum_client.dart';
import 'package:cw_ethereum/ethereum_transaction_credentials.dart';

class PendingEthereumTransaction with PendingTransaction {
  final EthereumClient client;
  final EthereumTransactionCredentials credentials;
  final String privateKey;
  final int amount;

  PendingEthereumTransaction({
    required this.client,
    required this.credentials,
    required this.privateKey,
    required this.amount,
  });

  @override
  String get amountFormatted => AmountConverter.amountIntToString(CryptoCurrency.eth, amount);

  @override
  Future<void> commit() async {
    for (var output in credentials.outputs) {
      await client.sendTransaction(privateKey, output.address, output.cryptoAmount!);
    }
  }

  @override
  // TODO: implement feeFormatted
  String get feeFormatted => "0.01";

  @override
  // TODO: implement hex
  String get hex => "hex";

  @override
  // TODO: implement id
  String get id => "id";
}
