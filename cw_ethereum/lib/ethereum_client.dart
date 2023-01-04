import 'package:cw_core/node.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class EthereumClient {
  late final Web3Client _client;

  Future<bool> connect(Node node) async {
    try {
      _client = Web3Client(node.uriRaw, Client());

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<EtherAmount> getBalance(String privateKey) async {
    final private = EthPrivateKey.fromHex(privateKey);

    return _client.getBalance(private.address);
  }

  Future<EtherAmount> getGasPrice() async => _client.getGasPrice();
}