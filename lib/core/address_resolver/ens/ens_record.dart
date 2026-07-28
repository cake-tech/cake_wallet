import 'package:cake_wallet/evm/evm.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:ens_dart/ens_dart.dart';
import 'package:web3dart/web3dart.dart';

class EnsRecord {
  static Future<String> fetchEnsAddress(
    String name,
    CryptoCurrency cur, {
    WalletBase? wallet,
  }) async {
    Web3Client? _client;

    if (wallet?.type == WalletType.ethereum || wallet?.type == WalletType.polygon) {
      _client = evm!.getWeb3Client(wallet!);
    }

    _client ??= Web3Client(
      'https://ethereum-rpc.publicnode.com',
      ProxyWrapper().getHttpIOClient(),
    );

    final ens = Ens(client: _client).withName(name);
    final coinType = getEnsCoinType(cur);

    if (coinType == null) {
      printV('Unsupported currency for ENS: $cur');
      return '';
    }

    try {
      // Every name points at its own resolver contract, so it has to be read from the
      // registry first. The ens_dart default is a single legacy resolver, which returns
      // stale (or empty) records for names that are not registered against it.
      final resolverAddress = await ens.getResolverAddress(ens.nodeHash);

      if (isZeroAddress(resolverAddress)) {
        printV('No ENS resolver set for $name');
        return '';
      }

      final resolver = Ens(client: ens.client, address: resolverAddress).withName(name);

      if (coinType == CoinType.ETH || coinType == CoinType.MATIC) {
        return (await resolver.getAddress()).hex;
      } else {
        return await resolver.getCoinAddress(coinType);
      }
    } catch (e) {
      printV(e);
      return '';
    }
  }

  static bool isZeroAddress(EthereumAddress address) =>
      address.addressBytes.every((byte) => byte == 0);

  static CoinType? getEnsCoinType(CryptoCurrency cur) => switch (cur) {
        CryptoCurrency.xmr => CoinType.XMR,
        CryptoCurrency.btc => CoinType.BTC,
        CryptoCurrency.ltc => CoinType.LTC,
        CryptoCurrency.eth => CoinType.ETH,
        CryptoCurrency.matic => CoinType.MATIC,
        _ => null,
      };
}
