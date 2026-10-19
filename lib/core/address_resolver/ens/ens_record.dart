import "dart:convert";
import "dart:typed_data";

import "package:cake_wallet/evm/evm.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:ens_dart/ens_dart.dart";
import "package:web3dart/crypto.dart";
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

    final registryEns = Ens(client: _client).withName(name);
    final coinType = getEnsCoinType(cur);

    if (coinType == null) {
      printV("Unsupported currency for ENS: $cur");
      return "";
    }

    try {
      final isEth = coinType == CoinType.ETH;
      final addrFn = _abi.functions[isEth ? 1 : 2];
      final data = addrFn.encodeCall([registryEns.nodeHash, if (!isEth) coinType.coinTypeInt]);
      final dnsName = Uint8List.fromList([
        for (final label in name.split(".")) ...[utf8.encode(label).length, ...utf8.encode(label)],
        0,
      ]);
      final res = await _client.call(
        contract: DeployedContract(_abi, _universalResolver),
        function: _abi.functions[0],
        params: [dnsName, data],
      );
      final out = addrFn.decodeReturnValues(bytesToHex(res[0] as Uint8List))[0];
      return out is EthereumAddress ? out.hex : bytesToHex(out as Uint8List);
    } catch (e) {
      printV(e);
      return "";
    }
  }

  static final _universalResolver =
      EthereumAddress.fromHex("0xeEeEEEeE14D718C2B47D9923Deab1335E144EeEe");

  static final _abi = ContractAbi.fromJson(
      '[{"name":"resolve","type":"function","stateMutability":"view","inputs":[{"name":"","type":"bytes"},{"name":"","type":"bytes"}],"outputs":[{"name":"","type":"bytes"},{"name":"","type":"address"}]},'
      '{"name":"addr","type":"function","stateMutability":"view","inputs":[{"name":"","type":"bytes32"}],"outputs":[{"name":"","type":"address"}]},'
      '{"name":"addr","type":"function","stateMutability":"view","inputs":[{"name":"","type":"bytes32"},{"name":"","type":"uint256"}],"outputs":[{"name":"","type":"bytes"}]}]',
      "UniversalResolver",
  );

  static CoinType? getEnsCoinType(CryptoCurrency cur) => switch (cur) {
        CryptoCurrency.xmr => CoinType.XMR,
        CryptoCurrency.btc => CoinType.BTC,
        CryptoCurrency.ltc => CoinType.LTC,
        CryptoCurrency.eth => CoinType.ETH,
        CryptoCurrency.maticpoly => CoinType.MATIC,
        _ => null,
      };
}
