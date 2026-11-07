import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'pivx_network.dart';

/// PIVX Core base58Prefixes[EXCHANGE_ADDRESS]; script OP_EXCHANGEADDR OP_DUP
/// OP_HASH160 <h> OP_EQUALVERIFY OP_CHECKSIG. A P2pkhAddress so base parsing
/// accepts it; fees price the serialized 26-byte script (35-byte output), not
/// P2PKH's 34. Consensus rejects it in any tx with Sapling data.
class PivxExchangeAddress extends P2pkhAddress {
  PivxExchangeAddress._(String h160)
      : super.fromHash160(h160: h160, network: PivxNetwork.mainnet);

  static const List<int> netVer = [0x01, 0xb9, 0xa2];
  static const int opExchangeAddr = 0xe0;

  /// Prefix + 20-byte hash + checksum base58s to exactly 36 chars.
  static bool looksLike(String address) =>
      address.startsWith('EXM') && address.length == 36;

  factory PivxExchangeAddress.fromAddress(String address) {
    final payload = Base58Decoder.checkDecode(address);
    if (payload.length != 23 ||
        !BytesUtils.bytesEqual(payload.sublist(0, 3), netVer)) {
      throw ArgumentException('Invalid PIVX exchange address');
    }
    return PivxExchangeAddress._(BytesUtils.toHexString(payload.sublist(3)));
  }

  /// Raw form, or Script.fromRaw's: 0xe0 read as a push length gives one
  /// 25-byte token that toBytes() re-emits behind 0x19. A bare push of the
  /// same bytes is indistinguishable; no wallet emits one.
  static PivxExchangeAddress? fromScript(Script script) {
    final b = script.toBytes();
    if (b.length != 26 ||
        (b[0] != opExchangeAddr && b[0] != 0x19) ||
        b[1] != 0x76 ||
        b[2] != 0xa9 ||
        b[3] != 0x14 ||
        b[24] != 0x88 ||
        b[25] != 0xac) {
      return null;
    }
    return PivxExchangeAddress._(BytesUtils.toHexString(b.sublist(4, 24)));
  }

  @override
  String toAddress([BasedUtxoNetwork? network]) => Base58Encoder.checkEncode(
      [...netVer, ...BytesUtils.fromHexString(addressProgram)]);

  @override
  Script toScriptPubKey() => Script(script: [
        opExchangeAddr,
        0x76,
        0xa9,
        0x14,
        ...BytesUtils.fromHexString(addressProgram),
        0x88,
        0xac,
      ]);
}
