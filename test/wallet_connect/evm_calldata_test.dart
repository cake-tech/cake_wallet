import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";

void main() {
  group("EvmCalldata.parse", () {
    test("splits selector and body", () {
      final calldata = EvmCalldata.parse("0xa9059cbb${wordInt(1)}");
      expect(calldata, isNotNull);
      expect(calldata!.selector, "a9059cbb");
      expect(calldata.body, wordInt(1));
    });

    test("lowercases checksummed-case calldata so selectors match", () {
      final calldata = EvmCalldata.parse("0xA9059CBB${wordInt(1).toUpperCase()}");
      expect(calldata!.selector, "a9059cbb");
    });

    test("rejects null and too-short payloads", () {
      expect(EvmCalldata.parse(null), isNull);
      expect(EvmCalldata.parse("0x"), isNull);
      expect(EvmCalldata.parse("0xa9059c"), isNull);
    });
  });

  group("word readers", () {
    const tokenA = "0x1111111111111111111111111111111111111111";

    test("addressAt reads a padded address and rejects dirty padding", () {
      final calldata = EvmCalldata.fromBody(wordAddr(tokenA));
      expect(calldata.addressAt(0), tokenA);

      final dirty = EvmCalldata.fromBody("ff${wordAddr(tokenA).substring(2)}");
      expect(dirty.addressAt(0), isNull);
    });

    test("uintAt and boolAt read in range and null out of range", () {
      final calldata = EvmCalldata.fromBody(wordInt(42) + wordInt(1) + wordInt(0));
      expect(calldata.uintAt(0), BigInt.from(42));
      expect(calldata.boolAt(1), isTrue);
      expect(calldata.boolAt(2), isFalse);
      expect(calldata.uintAt(3), isNull);
    });

    test("addressArrayAt follows the offset word", () {
      const tokenB = "0x2222222222222222222222222222222222222222";
      final body = wordInt(0x20) + addressArrayBody([tokenA, tokenB]);
      final calldata = EvmCalldata.fromBody(body);
      expect(calldata.addressArrayAt(0), [tokenA, tokenB]);
    });

    test("uintArrayAt reads values and rejects truncated bodies", () {
      final body = wordInt(0x20) + uintArrayBody([BigInt.one, BigInt.two]);
      final calldata = EvmCalldata.fromBody(body);
      expect(calldata.uintArrayAt(0), [BigInt.one, BigInt.two]);

      final truncated = EvmCalldata.fromBody(body.substring(0, body.length - 2));
      expect(truncated.uintArrayAt(0), isNull);
    });

    test("bytesArrayAt reads two elements", () {
      final body = wordInt(0x20) + bytesArrayBody(["aabb", "ccddee"]);
      final calldata = EvmCalldata.fromBody(body);
      expect(calldata.bytesArrayAt(0), ["aabb", "ccddee"]);
    });

    test("dynamicBytesAt reads a length-prefixed blob", () {
      final body = wordInt(0x20) + bytesBlob("01020304");
      final calldata = EvmCalldata.fromBody(body);
      expect(calldata.dynamicBytesAt(0), [1, 2, 3, 4]);
    });

    test("structAt slices at the stored byte offset", () {
      final body = wordInt(0x40) + wordInt(0x9990) + wordInt(7);
      final calldata = EvmCalldata.fromBody(body);
      expect(calldata.structAt(0)!.uintAt(0), BigInt.from(7));
      expect(calldata.structAt(1), isNull);
    });
  });
}
