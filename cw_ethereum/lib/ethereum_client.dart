import 'package:cw_core/node.dart';
import 'package:cw_ethereum/ethereum_transaction_priority.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class EthereumClient {
  Web3Client? _client;

  bool connect(Node node) {
    try {
      _client = Web3Client(node.uri.toString(), Client());

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<EtherAmount> getBalance(String privateKey) async {
    final private = EthPrivateKey.fromHex(privateKey);

    return _client!.getBalance(private.address);
  }

  Future<int> getGasUnitPrice() async {
    final gasPrice = await _client!.getGasPrice();
    return gasPrice.getInWei.toInt();
  }

  Future<List<int>> getEstimatedGasForPriorities() async {
    final result = await Future.wait(EthereumTransactionPriority.all.map(
      (priority) => _client!.estimateGas(
        maxPriorityFeePerGas: EtherAmount.fromUnitAndValue(EtherUnit.gwei, priority.tip),
        maxFeePerGas: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 100),

      ),
    ));

    return result.map((e) => e.toInt()).toList();
  }
}
