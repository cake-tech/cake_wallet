import 'package:cw_core/pending_transaction.dart';
import 'package:cw_ethereum/ethereum_client.dart';
import 'package:cw_ethereum/ethereum_transaction_credentials.dart';

class PendingEthereumTransaction with PendingTransaction {
  final EthereumClient client;
  final EthereumTransactionCredentials credentials;
  final String privateKey;

  PendingEthereumTransaction({
    required this.client,
    required this.credentials,
    required this.privateKey,
  });

  @override
  // TODO: implement amountFormatted
  String get amountFormatted => throw UnimplementedError();

  @override
  Future<void> commit() async {
    for (var output in credentials.outputs) {
      await client.sendTransaction(privateKey, output.address, output.cryptoAmount!);
    }
  }

  @override
  // TODO: implement feeFormatted
  String get feeFormatted => throw UnimplementedError();

  @override
  // TODO: implement hex
  String get hex => throw UnimplementedError();

  @override
  // TODO: implement id
  String get id => throw UnimplementedError();
}
