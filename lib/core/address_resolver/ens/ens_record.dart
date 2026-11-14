import "package:cake_wallet/core/address_resolver/ens/ens_universal_resolver.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:ens_dart/ens_dart.dart";
import "package:web3dart/web3dart.dart";

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
      "https://ethereum-rpc.publicnode.com",
      ProxyWrapper().getHttpIOClient(),
    );

    final coinType = getEnsCoinType(cur);

    if (coinType == null) {
      printV("Unsupported currency for ENS: $cur");
      return "";
    }

    return EnsUniversalResolver.resolveAddress(_client, name, coinType);
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
