import 'dart:typed_data';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart' as web3;

// Envelope/signer checks from the final native adapter. Calldata effects remain
// trusted to the provider; this does not decode or prove contract semantics.
({String to, String valueBaseUnits, String? data, String gasLimit, String transactionHash}) inspectPegarouteEvm(
  String rawHex,
  {required int chainId, required String sender}
) {
  try {
    final bytes = hexToBytes(rawHex);
    if (bytes.isEmpty) throw const FormatException('Empty transaction');
    final typed = bytes.first == 2;
    final encoded = typed ? bytes.sublist(1) : bytes;
    final fields = _nativeTransactionFields(encoded);
    if (fields.length != (typed ? 12 : 9) ||
        bytesToHex(web3.encode(fields)) != bytesToHex(encoded)) {
      throw const FormatException('Noncanonical transaction');
    }
    Uint8List field(int i) => fields[i] as Uint8List;
    BigInt number(int i) {
      final value = field(i);
      if (value.length > 32 || value.isNotEmpty && value.first == 0) {
        throw const FormatException('Noncanonical integer');
      }
      return value.isEmpty ? BigInt.zero : bytesToUnsignedInt(value);
    }

    final v = number(typed ? 9 : 6);
    final chain = typed ? number(0) : (v - BigInt.from(35)) ~/ BigInt.two;
    final parity = typed ? v : (v - BigInt.from(35)) % BigInt.two;
    number(typed ? 1 : 0); // nonce
    final tip = typed ? number(2) : BigInt.zero;
    final maxFee = number(typed ? 3 : 1);
    final gas = number(typed ? 4 : 2);
    final amount = number(typed ? 6 : 4);
    final to = field(typed ? 5 : 3);
    final data = field(typed ? 7 : 5);
    final r = number(typed ? 10 : 7);
    final s = number(typed ? 11 : 8);
    final order =
        BigInt.parse('fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141', radix: 16);
    if (chain != BigInt.from(chainId) ||
        !typed && v < BigInt.from(35) ||
        to.length != 20 ||
        typed && (fields[8] is! List || (fields[8] as List).isNotEmpty) ||
        gas < BigInt.from(21000) ||
        maxFee <= BigInt.zero ||
        tip > maxFee ||
        parity > BigInt.one ||
        r <= BigInt.zero ||
        r >= order ||
        s <= BigInt.zero ||
        s > order ~/ BigInt.two) {
      throw const FormatException('Unsupported EVM transaction');
    }
    final digest = keccak256(Uint8List.fromList(typed
        ? [2, ...web3.encode(fields.sublist(0, 9))]
        : web3.encode(
            [...fields.sublist(0, 6), unsignedIntToBytes(chain), Uint8List(0), Uint8List(0)])));
    final recovered = ecRecover(digest, MsgSignature(r, s, parity.toInt() + 27));
    final publicKey = Uint8List(64);
    if (recovered.length > 64) throw const FormatException('Invalid public key');
    publicKey.setRange(64 - recovered.length, 64, recovered);
    final signer = bytesToHex(publicKeyToAddress(publicKey), include0x: true);
    if (signer.toLowerCase() != sender.toLowerCase()) {
      throw const FormatException('Signed by a different wallet');
    }
    return (
      to: bytesToHex(to, include0x: true),
      valueBaseUnits: amount.toString(),
      data: data.isEmpty ? null : bytesToHex(data, include0x: true),
      gasLimit: gas.toString(),
      transactionHash: bytesToHex(keccak256(bytes), include0x: true),
    );
  } catch (_) {
    throw const FormatException('Signed EVM instructions could not be verified');
  }
}

// Narrow RLP reader: one transaction list with byte fields and an empty access
// list. Round-trip encoding above additionally rejects noncanonical lengths.
List<Object> _nativeTransactionFields(Uint8List bytes) {
  if (bytes.length > 65535) throw const FormatException('Oversized EVM transaction');
  var cursor = 0;
  Object read({bool root = false}) {
    final prefix = bytes[cursor++];
    if (prefix < 0x80) return Uint8List.fromList([prefix]);
    final list = prefix >= 0xc0;
    final short = list ? 0xc0 : 0x80;
    final long = list ? 0xf7 : 0xb7;
    var length = prefix - short;
    if (prefix > long) {
      final lengthBytes = prefix - long;
      if (lengthBytes > 2) throw const FormatException('Oversized RLP length');
      length = 0;
      for (var i = 0; i < lengthBytes; i++) {
        length = (length << 8) | bytes[cursor++];
      }
    }
    final end = cursor + length;
    if (end > bytes.length) throw const FormatException('Truncated RLP');
    if (list) {
      if (!root && length != 0) throw const FormatException('Unsupported access list');
      final result = <Object>[];
      while (cursor < end) {
        result.add(read());
      }
      if (cursor != end) throw const FormatException('Invalid RLP length');
      return result;
    }
    final result = Uint8List.fromList(bytes.sublist(cursor, end));
    cursor = end;
    return result;
  }

  final fields = read(root: true);
  if (cursor != bytes.length || fields is! List<Object> || fields is Uint8List) {
    throw const FormatException('Invalid transaction list');
  }
  return fields;
}

