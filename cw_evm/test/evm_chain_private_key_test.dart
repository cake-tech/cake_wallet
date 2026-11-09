import "package:cw_evm/utils/evm_chain_utils.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("EVMChainUtils.isValidPrivateKey", () {
    const validKey = "4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f362318";
    const curveOrder = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141";
    const curveOrderMinusOne = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140";

    test("accepts a 32-byte hex key with or without a 0x prefix, in either case", () {
      expect(EVMChainUtils.isValidPrivateKey(validKey), isTrue);
      expect(EVMChainUtils.isValidPrivateKey("0x$validKey"), isTrue);
      expect(EVMChainUtils.isValidPrivateKey(validKey.toUpperCase()), isTrue);
      expect(EVMChainUtils.isValidPrivateKey(curveOrderMinusOne), isTrue);
    });

    test("rejects empty and non-hex input", () {
      expect(EVMChainUtils.isValidPrivateKey(""), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("0x"), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("not a private key"), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("z" * 64), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("$validKey "), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("$validKey\n"), isFalse);
    });

    test("rejects keys that are not exactly 32 bytes", () {
      expect(EVMChainUtils.isValidPrivateKey(validKey.substring(0, 62)), isFalse);
      expect(EVMChainUtils.isValidPrivateKey(validKey.substring(0, 63)), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("${validKey}00"), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("$validKey$validKey"), isFalse);
    });

    test("rejects keys outside the secp256k1 scalar range", () {
      expect(EVMChainUtils.isValidPrivateKey("0" * 64), isFalse);
      expect(EVMChainUtils.isValidPrivateKey(curveOrder), isFalse);
      expect(EVMChainUtils.isValidPrivateKey("f" * 64), isFalse);
    });
  });
}
