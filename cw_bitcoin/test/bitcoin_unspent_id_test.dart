import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_unspent.dart";
import "package:flutter_test/flutter_test.dart";

BitcoinAddressRecord record(String address, int index, {BitcoinAddressType? type}) =>
    BitcoinAddressRecord(
      address,
      index: index,
      type: type ?? P2pkhAddressType.p2pkh,
      network: LitecoinNetwork.mainnet,
    );

void main() {
  group("BitcoinUnspent.id", () {
    test("is the transaction hash and output index", () {
      final coin = BitcoinUnspent(record("addr", 0), "abc123", 1000, 2);
      expect(coin.id, "abc123:2");
    });

    test("distinguishes two outputs of the same transaction", () {
      final first = BitcoinUnspent(record("addr", 0), "abc123", 1000, 0);
      final second = BitcoinUnspent(record("addr", 0), "abc123", 500, 1);

      // Two outputs of one transaction is the ordinary case, and the previous
      // implementation matched stored records on the hash alone.
      expect(first.id, isNot(second.id));
    });

    test("does not change with the value", () {
      final cheap = BitcoinUnspent(record("addr", 0), "abc123", 1, 0);
      final rich = BitcoinUnspent(record("addr", 0), "abc123", 999999, 0);
      expect(cheap.id, rich.id);
    });

    test("does not change with the address record's index", () {
      final early = BitcoinUnspent(record("addr", 0), "abc123", 1000, 0);
      final late_ = BitcoinUnspent(record("addr", 41), "abc123", 1000, 0);
      expect(early.id, late_.id);
    });
  });

  group("MWEB outputs", () {
    // MWEB coins are built with the index of their address in the wallet's MWEB
    // address list where the output index would go, and that list grows.
    BitcoinUnspent mweb(String outputId, int addressIndex) => BitcoinUnspent(
          record("ltcmweb1qq...", addressIndex, type: SegwitAddresType.mweb),
          outputId,
          1000,
          addressIndex,
        );

    test("are identified by their output id alone", () {
      expect(mweb("output-abc", 3).id, "output-abc");
    });

    test("keep their identity when the address list grows", () {
      // The bug this closes: the same output, seen after more MWEB addresses
      // were generated, used to hash to a different id and silently lose the
      // user's frozen flag and note.
      expect(mweb("output-abc", 3).id, mweb("output-abc", 57).id);
    });

    test("two different outputs stay distinct", () {
      expect(mweb("output-abc", 0).id, isNot(mweb("output-def", 0).id));
    });

    test("do not collide with a regular output's id shape", () {
      final regular = BitcoinUnspent(record("ltc1q...", 0), "output-abc", 1000, 0);
      expect(mweb("output-abc", 0).id, isNot(regular.id));
    });
  });
}
