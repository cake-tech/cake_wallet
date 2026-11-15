import "dart:convert";
import "dart:typed_data";

import "package:cw_core/utils/print_verbose.dart";
import "package:ens_dart/ens_dart.dart";
import "package:web3dart/crypto.dart";
import "package:web3dart/web3dart.dart";

class EnsUniversalResolver {
  static Future<String> resolveAddress(Web3Client client, String name, CoinType coinType) async {
    final labels = _labels(name);
    if (labels == null) {
      return "";
    }

    try {
      final isEth = coinType == CoinType.ETH;
      final addrFn = isEth ? _addr : _addrByCoinType;
      final data = addrFn.encodeCall([_namehash(labels), if (!isEth) coinType.coinTypeInt]);
      final res = await client.call(
        contract: _contract,
        function: _resolve,
        params: [_dnsEncode(labels), data],
      );
      final out = addrFn.decodeReturnValues(bytesToHex(res[0] as Uint8List))[0];
      return out is EthereumAddress ? out.hex : bytesToHex(out as Uint8List);
    } catch (e) {
      printV(e);
      return "";
    }
  }

  static List<Uint8List>? _labels(String name) {
    if (!_isVisibleAscii(name)) {
      return null;
    }
    final labels = name.toLowerCase().split(".").map(utf8.encode).toList();
    return labels.any((label) => label.isEmpty || label.length > 255) ? null : labels;
  }

  static bool _isVisibleAscii(String name) =>
      name.codeUnits.every((unit) => unit >= 0x21 && unit <= 0x7e);

  static Uint8List _namehash(List<Uint8List> labels) => labels.reversed.fold(
        Uint8List(32),
        (node, label) => keccak256(Uint8List.fromList([...node, ...keccak256(label)])),
      );

  static Uint8List _dnsEncode(List<Uint8List> labels) => Uint8List.fromList([
        for (final label in labels) ...[label.length, ...label],
        0,
      ]);

  static final _abi = ContractAbi.fromJson(
    '[{"name":"resolve","type":"function","stateMutability":"view","inputs":[{"name":"","type":"bytes"},{"name":"","type":"bytes"}],"outputs":[{"name":"","type":"bytes"},{"name":"","type":"address"}]},'
        '{"name":"addr","type":"function","stateMutability":"view","inputs":[{"name":"","type":"bytes32"}],"outputs":[{"name":"","type":"address"}]},'
        '{"name":"addr","type":"function","stateMutability":"view","inputs":[{"name":"","type":"bytes32"},{"name":"","type":"uint256"}],"outputs":[{"name":"","type":"bytes"}]}]',
    "UniversalResolver",
  );

  static final _resolve = _abi.functions[0];
  static final _addr = _abi.functions[1];
  static final _addrByCoinType = _abi.functions[2];

  static final _contract = DeployedContract(
    _abi,
    EthereumAddress.fromHex("0xeEeEEEeE14D718C2B47D9923Deab1335E144EeEe"),
  );
}
