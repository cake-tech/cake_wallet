import 'package:cake_wallet/evm/evm.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
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

    final ens = Ens(client: _client);
    final coinType = getEnsCoinType(cur);

    if (coinType == null) {
      printV('Unsupported currency for ENS: $cur');
      return '';
    }

    try {
      if (coinType == CoinType.ETH || coinType == CoinType.MATIC) {
        return (await ens.withName(name).getAddress()).hex;
      } else {
        return await ens.withName(name).getCoinAddress(coinType);
      }
    } catch (e) {
      printV(e);
      return '';
    }
  }

  static CoinType? getEnsCoinType(CryptoCurrency cur) {
    // ERC-20 tokens live at the recipient's Ethereum mainnet account, which is
    // exactly what the `addr(60)` ETH record points at, so they share it.
    if (isEthereumMainnetToken(cur)) return CoinType.ETH;

    return switch (cur) {
      CryptoCurrency.xmr => CoinType.XMR,
      CryptoCurrency.btc => CoinType.BTC,
      CryptoCurrency.ltc => CoinType.LTC,
      CryptoCurrency.eth => CoinType.ETH,
      CryptoCurrency.matic => CoinType.MATIC,
      _ => null,
    };
  }

  /// Whether [cur] is a token issued on Ethereum mainnet (chain id 1).
  ///
  /// EVM chain tokens are tagged with the chain they belong to
  /// (`EVMChainUtils.getDefaultTokenTag`: ETH / POL / BASE / ARB / BSC), and
  /// `EVMChainWallet` drops any token whose tag does not match the selected
  /// chain, so the tag is a reliable discriminator here.
  ///
  /// Tokens on the other EVM chains are deliberately excluded: resolving them
  /// would require reading that chain's own ENS coin record, and `addr(60)`
  /// is allowed to differ from it.
  static bool isEthereumMainnetToken(CryptoCurrency cur) =>
      cur is Erc20Token && cur.tag?.toUpperCase() == 'ETH';
}
