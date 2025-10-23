import 'package:cake_wallet/base/base.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:ens_dart/ens_dart.dart';
import 'package:web3dart/web3dart.dart';

class EnsRecord {
  
  static Future<String> fetchEnsAddress(String name, {WalletBase? wallet}) async {

    Web3Client? _client;

    if (wallet != null && wallet.type == WalletType.ethereum) {
      _client = ethereum!.getWeb3Client(wallet);
    }
    
    if (wallet != null && wallet.type == WalletType.polygon) {
      _client = polygon!.getWeb3Client(wallet);
    }

    if (wallet != null && wallet.type == WalletType.base) {
      _client = base!.getWeb3Client(wallet);
    }

    if (_client == null) {
      late final client = ProxyWrapper().getHttpIOClient();

      _client = Web3Client("https://ethereum-rpc.publicnode.com", client);
    }

    try {
      final ens = Ens(client: _client);

      if (wallet != null) {
        switch (wallet.type) {
          case WalletType.monero:
            return await ens.withName(name).getCoinAddress(CoinType.XMR);
          case WalletType.bitcoin:
            return await ens.withName(name).getCoinAddress(CoinType.BTC);
          case WalletType.litecoin:
            return await ens.withName(name).getCoinAddress(CoinType.LTC);
          case WalletType.haven:
            return await ens.withName(name).getCoinAddress(CoinType.XHV);
          case WalletType.ethereum:
          case WalletType.polygon:
          case WalletType.base:
          default:
            return (await ens.withName(name).getAddress()).hex;
        }
      }

      final addr = await ens.withName(name).getAddress();
      return addr.hex;
    } catch (e) {
      printV(e);
      return "";
    }
  }
}
