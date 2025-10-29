import "dart:typed_data";

import "package:cw_evm/evm_chain_formatter.dart";
import "package:cw_evm/utils/rlp_decode.dart";
import "package:flutter_test/flutter_test.dart";
import "package:web3dart/crypto.dart";
import "package:web3dart/src/utils/rlp.dart" as rlp;

void main() {
  group("EVMChainFormatter", () {
    group("truncateDecimals", () {
      test("no decimals", () => expect(EVMChainFormatter.truncateDecimals("5", 6), "5"));
      test("less than max decimals",
          () => expect(EVMChainFormatter.truncateDecimals("5.00001", 6), "5.00001"));
      test("max decimals",
          () => expect(EVMChainFormatter.truncateDecimals("5.000001", 6), "5.000001"));
      test("more than max decimals",
          () => expect(EVMChainFormatter.truncateDecimals("5.0000001", 6), "5.000000"));
    });
  });
  group("rlp decode", () {
    test("0x05", () => expect(decode(hexToBytes("0x05")), [5]));
    test(
      "0xc88363617483646f67",
      () => expect(
        decode(hexToBytes("0xc88363617483646f67")),
        [
          [99, 97, 116],
          [100, 111, 103]
        ],
      ),
    );

    test(
      "cat dog",
      () => expect(
        decode(Uint8List.fromList(rlp.encode(["cat", "dog"]))),
        [
          [99, 97, 116],
          [100, 111, 103]
        ],
      ),
    );
  });
}
