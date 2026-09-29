import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';

/// Decodes only the declared codec. Keep both raw text and label in the binding.
List<int> decodePegarouteSolanaTransaction(String value, String encoding) {
  // Bound Base58's numeric decoding before doing work on provider input.
  // A 1232-byte packet needs at most 2466 characters (0x-prefixed hex).
  if (value.length > 2466) throw const FormatException('Solana transaction text is too long');
  Never invalid() => throw const FormatException('Invalid Solana transaction encoding');
  try {
    if (value.isEmpty || value.trim() != value) invalid();
    final List<int> bytes;
    switch (encoding) {
      case 'base58':
        if (!RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$').hasMatch(value)) invalid();
        bytes = Base58Decoder.decode(value);
        if (Base58Encoder.encode(bytes) != value) invalid();
        break;
      case 'base64':
        if (value.length % 4 != 0 || !RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(value)) invalid();
        bytes = base64Decode(value);
        if (base64Encode(bytes) != value) invalid();
        break;
      case 'hex':
        final hex = value.startsWith('0x') ? value.substring(2) : value;
        if (!hex.length.isEven || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) invalid();
        bytes = BytesUtils.fromHexString(hex);
        break;
      default:
        return invalid();
    }
    if (bytes.length > 1232) invalid();
    return bytes;
  } catch (_) {
    return invalid();
  }
}

bool isValidPegarouteSolanaTransaction(String value, String? encoding) {
  if (encoding == null) return false;
  try {
    decodePegarouteSolanaTransaction(value, encoding);
    return true;
  } catch (_) {
    return false;
  }
}
