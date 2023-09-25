import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:ens_dart/ens_dart.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class EnsRecord {
  static Future<String> fetchEnsAddress(String name, {WalletBase? wallet}) async {
    Web3Client? _client;

    if (wallet != null && wallet.type == WalletType.ethereum) {
      _client = ethereum!.getWeb3Client(wallet) as Web3Client?;
    }

    if (_client == null) {
      _client = Web3Client("ethereum.publicnode.com", Client());
    }

    try {
      final ens = Ens(client: _client);

      final addr = await ens.withName(name).getAddress();
      return addr.hex;
    } catch (e) {
      print(e);
      return "";
    }
  }
}
