import 'dart:typed_data';

import 'package:web3dart/crypto.dart';

/// RLP Decode
///
/// Adapted from https://github.com/ethereumjs/ethereumjs-monorepo/tree/master/packages/rlp

class _Decoded {
  Uint8List remainder;
  List data;

  _Decoded(this.data, this.remainder);
}

int _decodeLength(Uint8List v) {
  if (v[0] == 0) throw Exception('invalid RLP: extra zeros');
  return int.parse(bytesToHex(v), radix: 16);
}

_Decoded _decode(Uint8List input) {
  final firstByte = input[0];

  if (firstByte <= 0x7f) {
    // a single byte whose value is in the [0x00, 0x7f] range, that byte is its own RLP encoding.
    return _Decoded(input.sublist(0, 1), input.sublist(1));
  } else if (firstByte <= 0xb7) {
    // string is 0-55 bytes long. A single byte with value 0x80 plus the length of the string followed by the string
    // The range of the first byte is [0x80, 0xb7]
    final length = firstByte - 0x7f;

    // set 0x80 null to 0
    final data = firstByte == 0x80 ? Uint8List(0) : input.sublist(1, length);

    if (length == 2 && data[0] < 0x80) {
      throw Exception('invalid RLP encoding: invalid prefix, single byte < 0x80 are not prefixed');
    }

    return _Decoded(data, input.sublist(length));
  } else if (firstByte <= 0xbf) {
    // string is greater than 55 bytes long. A single byte with the value (0xb7 plus the length of the length),
    // followed by the length, followed by the string
    final lLength = firstByte - 0xb6;
    if (input.length - 1 < lLength) {
      throw Exception('invalid RLP: not enough bytes for string length');
    }

    final length = _decodeLength(input.sublist(1, lLength));
    if (length <= 55) {
      throw Exception('invalid RLP: expected string length to be greater than 55');
    }

    final data = input.sublist(lLength, length + lLength);
    return _Decoded(data, input.sublist(length + lLength));
  } else if (firstByte <= 0xf7) {
    // a list between 0-55 bytes long
    final length = firstByte - 0xbf;
    var innerRemainder = input.sublist(1, length);

    final decoded = [];
    while (innerRemainder.isNotEmpty) {
      final d = _decode(innerRemainder);
      decoded.add(d.data);
      innerRemainder = d.remainder;
    }

    return _Decoded(decoded, input.sublist(length));
  } else {
    // a list over 55 bytes long
    final lLength = firstByte - 0xf6;

    final length = _decodeLength(input.sublist(1, lLength));
    if (length < 56) {
      throw Exception('invalid RLP: encoded list too short');
    }

    final totalLength = lLength + length;
    if (totalLength > input.length) {
      throw Exception('invalid RLP: total length is larger than the data');
    }

    var innerRemainder = input.sublist(lLength, totalLength);
    final decoded = [];
    while (innerRemainder.isNotEmpty) {
      final d = _decode(innerRemainder);
      decoded.add(d.data);
      innerRemainder = d.remainder;
    }

    return _Decoded(decoded, input.sublist(totalLength));
  }
}

/// RLP Decoding based on https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp/
List decode(Uint8List input) {
  final decoded = _decode(input);

  if (decoded.remainder.isNotEmpty) throw Exception('invalid RLP: remainder must be zero');

  return decoded.data;
}
