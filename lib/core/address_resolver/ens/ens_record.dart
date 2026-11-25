import "package:cake_wallet/core/address_resolver/ens/ens_universal_resolver.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/wallet_base.dart";
import "package:ens_dart/ens_dart.dart";
import "package:web3dart/web3dart.dart";

class EnsRecord {
  static Future<String> fetchEnsAddress(
    String name,
    CryptoCurrency cur, {
    WalletBase? wallet,
  }) async {
    final coinType = getEnsCoinType(cur);
    if (coinType == null) {
      printV("Unsupported currency for ENS: $cur");
      return "";
    }

    final walletClient = wallet?.chainId == 1 ? evm?.getWeb3Client(wallet!) : null;
    if (walletClient != null) {
      return EnsUniversalResolver.resolveAddress(walletClient, name, coinType);
    }

    final httpClient = ProxyWrapper().getHttpIOClient();
    try {
      final client = Web3Client("https://ethereum-rpc.publicnode.com", httpClient);
      return await EnsUniversalResolver.resolveAddress(client, name, coinType);
    } finally {
      httpClient.close();
    }
  }

  static CoinType? getEnsCoinType(CryptoCurrency cur) => switch (cur) {
        CryptoCurrency.xmr => CoinType.XMR,
        CryptoCurrency.btc => CoinType.BTC,
        CryptoCurrency.ltc => CoinType.LTC,
        CryptoCurrency.eth => CoinType.ETH,
        CryptoCurrency.maticpoly => CoinType.MATIC,
        _ => null,
      };
}
