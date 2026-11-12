import "package:cw_evm/utils/evm_chain_utils.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("EVMChainUtils.isValidPrivateKey", () {
    const validKey = "4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f362318";
    const curveOrder = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141";
    final curveOrderInt = BigInt.parse(curveOrder, radix: 16);

    String hexOf(BigInt value) {
      final hex = value.toRadixString(16);
      return hex.length.isOdd ? "0$hex" : hex;
    }

    test("accepts a 32-byte hex key with or without a 0x prefix, in either case", () {
      expect(EVMChainUtils.isValidPrivateKey(validKey), isTrue);
      expect(EVMChainUtils.isValidPrivateKey("0x$validKey"), isTrue);
      expect(EVMChainUtils.isValidPrivateKey(validKey.toUpperCase()), isTrue);
      expect(EVMChainUtils.isValidPrivateKey(hexOf(curveOrderInt - BigInt.one)), isTrue);
    });

    test("keeps accepting the other even lengths that restored on earlier versions", () {
      expect(EVMChainUtils.isValidPrivateKey("01"), isTrue);
      expect(EVMChainUtils.isValidPrivateKey(validKey.substring(0, 62)), isTrue);
      expect(EVMChainUtils.isValidPrivateKey("${validKey}00"), isTrue);
      expect(EVMChainUtils.isValidPrivateKey("$validKey$validKey"), isTrue);
      expect(EVMChainUtils.isValidPrivateKey("f" * 64), isTrue);
      expect(EVMChainUtils.isValidPrivateKey(hexOf(curveOrderInt + BigInt.one)), isTrue);
    });

    test("rejects input that EthPrivateKey.fromHex cannot parse", () {
      expect(EVMChainUtils.isValidPrivateKey("not a private key"), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("z" * 64), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("0X$validKey"), isFalse);
      expect(EVMChainUtils.isValidPrivateKey(validKey.substring(0, 63)), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("$validKey "), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("$validKey\n"), isFalse);
    });

    test("rejects empty input and keys that are zero modulo the curve order", () {
      expect(EVMChainUtils.isValidPrivateKey(""), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("0x"), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("00"), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("0" * 64), isFalse);
      expect(EVMChainUtils.isValidPrivateKey(curveOrder), isFalse);
      expect(EVMChainUtils.isValidPrivateKey(hexOf(curveOrderInt * BigInt.two)), isFalse);
    });
  });
}
