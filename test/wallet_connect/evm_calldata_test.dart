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

    test("no calldata parses to null", () {
      expect(EvmCalldata.parse(null), isNull);
      expect(EvmCalldata.parse("0x"), isNull);
      expect(EvmCalldata.parse(""), isNull);
    });

    test("fewer than four bytes are kept, so a fallback call is not read as no calldata", () {
      final calldata = EvmCalldata.parse("0xA9059C");
      expect(calldata!.selector, "a9059c");
      expect(calldata.body, isEmpty);
      expect(calldata.wordAt(0), isNull);
    });
  });

  group("word readers", () {
    const tokenA = "0x1111111111111111111111111111111111111111";

    test("addressAt reads the low 160 bits, whatever the high bytes hold", () {
      final calldata = EvmCalldata.fromBody(wordAddr(tokenA));
      expect(calldata.addressAt(0), tokenA);

      final dirty = EvmCalldata.fromBody("ffffffffffffffffffffffff${tokenA.substring(2)}");
      expect(dirty.addressAt(0), tokenA);
      expect(dirty.addressAt(1), isNull);
    });

    test("boundedUintAt refuses a value larger than the data it would index", () {
      final calldata = EvmCalldata.fromBody(
        wordInt(96) + wordInt(97) + word((BigInt.one << 256) - BigInt.one),
      );
      expect(calldata.boundedUintAt(0), 96);
      expect(calldata.boundedUintAt(1), isNull);
      expect(calldata.boundedUintAt(2), isNull);
      expect(calldata.boundedUintAt(3), isNull);
    });

    test("uintAt and boolAt read in range and null out of range", () {
      final calldata = EvmCalldata.fromBody(wordInt(42) + wordInt(1) + wordInt(0));
      expect(calldata.uintAt(0), BigInt.from(42));
      expect(calldata.boolAt(1), isTrue);
      expect(calldata.boolAt(2), isFalse);
      expect(calldata.uintAt(3), isNull);
    });

    test("addressArrayAt follows the offset word and reads the low 160 bits", () {
      const tokenB = "0x2222222222222222222222222222222222222222";
      final body = wordInt(0x20) + addressArrayBody([tokenA, tokenB]);
      final calldata = EvmCalldata.fromBody(body);
      expect(calldata.addressArrayAt(0), [tokenA, tokenB]);

      final dirty = EvmCalldata.fromBody(
        "${wordInt(0x20)}${wordInt(2)}${wordAddr(tokenA)}"
        "ffffffffffffffffffffffff${tokenB.substring(2)}",
      );
      expect(dirty.addressArrayAt(0), [tokenA, tokenB]);
    });

    test("addressArrayAt refuses an offset or a length larger than the data", () {
      final pastTheEnd = EvmCalldata.fromBody(wordInt(0x400) + addressArrayBody([tokenA]));
      expect(pastTheEnd.addressArrayAt(0), isNull);

      final tooLong = EvmCalldata.fromBody(wordInt(0x20) + wordInt(3) + wordAddr(tokenA));
      expect(tooLong.addressArrayAt(0), isNull);

      final overflowing = EvmCalldata.fromBody(
        wordInt(0x20) + word((BigInt.one << 256) - BigInt.one) + wordAddr(tokenA),
      );
      expect(overflowing.addressArrayAt(0), isNull);
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

    test("bytesArrayAt refuses elements that add up to more than the data", () {
      const element = "aabbccdd";
      String aliased(int count) =>
          wordInt(0x20) + wordInt(count) + wordInt(count * 32) * count + bytesBlob(element * 16);

      expect(EvmCalldata.fromBody(aliased(1)).bytesArrayAt(0), [element * 16]);
      expect(EvmCalldata.fromBody(aliased(8)).bytesArrayAt(0), isNull);
    });

    test("dynamicBytesAt reads a length-prefixed blob", () {
      final body = wordInt(0x20) + bytesBlob("01020304");
      final calldata = EvmCalldata.fromBody(body);
      expect(calldata.dynamicBytesAt(0), [1, 2, 3, 4]);
    });

    test("every offset reader refuses an offset that leaves no word to read", () {
      final atTheEnd = EvmCalldata.fromBody(wordInt(0x20));
      expect(atTheEnd.structAt(0), isNull);
      expect(atTheEnd.addressArrayAt(0), isNull);
      expect(atTheEnd.uintArrayAt(0), isNull);
      expect(atTheEnd.dynamicBytesAt(0), isNull);
      expect(atTheEnd.bytesArrayAt(0), isNull);
    });

    test("uintArrayAt, dynamicBytesAt and bytesArrayAt refuse a length larger than the data", () {
      final uint256Max = (BigInt.one << 256) - BigInt.one;
      for (final length in [BigInt.two, uint256Max]) {
        final oneWord = EvmCalldata.fromBody(wordInt(0x20) + word(length) + wordInt(7));
        expect(oneWord.uintArrayAt(0), isNull, reason: "$length values");
        expect(oneWord.bytesArrayAt(0), isNull, reason: "$length elements");
      }
      for (final length in [BigInt.from(33), uint256Max]) {
        final oneWord = EvmCalldata.fromBody(wordInt(0x20) + word(length) + wordInt(7));
        expect(oneWord.dynamicBytesAt(0), isNull, reason: "$length bytes");
      }

      final exactFit = EvmCalldata.fromBody(wordInt(0x20) + wordInt(1) + wordInt(7));
      expect(exactFit.uintArrayAt(0), [BigInt.from(7)]);
      expect(exactFit.dynamicBytesAt(0), [0]);
    });

    test("structAt slices at the stored byte offset", () {
      final body = wordInt(0x40) + wordInt(0x9990) + wordInt(7);
      final calldata = EvmCalldata.fromBody(body);
      expect(calldata.structAt(0)!.uintAt(0), BigInt.from(7));
      expect(calldata.structAt(1), isNull);
    });
  });
}
