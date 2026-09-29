import 'dart:typed_data';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart' as web3;

/// No key or signing operation: construct a fixture with fixed r/s, then recover
/// its hypothetical sender. It is never sent to a node. A public EIP-155 vector
/// separately checks the production decoder against an independent known sender.
({String hex, String sender, String hash}) syntheticEvmEnvelope({required String to,
    required BigInt value, String data = '0x', int chainId = 1, int gas = 25000,
    int gasPrice = 40000000000, int nonce = 0}) {
  Uint8List number(BigInt value) => value == BigInt.zero ? Uint8List(0) : unsignedIntToBytes(value);
  final fields = <Object>[number(BigInt.from(nonce)), number(BigInt.from(gasPrice)),
    number(BigInt.from(gas)), hexToBytes(to), number(value), hexToBytes(data)];
  final digest = keccak256(Uint8List.fromList(web3.encode([
    ...fields, number(BigInt.from(chainId)), Uint8List(0), Uint8List(0),
  ])));
  final recovered = ecRecover(digest, MsgSignature(BigInt.one, BigInt.one, 27));
  final publicKey = Uint8List(64)..setRange(64 - recovered.length, 64, recovered);
  final bytes = Uint8List.fromList(web3.encode([
    ...fields, number(BigInt.from(chainId * 2 + 35)), number(BigInt.one), number(BigInt.one),
  ]));
  return (hex: bytesToHex(bytes), sender: bytesToHex(publicKeyToAddress(publicKey), include0x: true),
      hash: bytesToHex(keccak256(bytes), include0x: true));
}
