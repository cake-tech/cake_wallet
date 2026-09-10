import "package:cw_core/coin_control/coin_selection.dart";
import "package:cw_core/unspent_transaction_output.dart";
import "package:flutter_test/flutter_test.dart";

Unspent coin(String hash, int vout, {int value = 1000, String? keyImage}) =>
    Unspent("addr", hash, value, vout, keyImage);

void main() {
  group("Unspent.id", () {
    test("is the hash and index when there is no key image", () {
      expect(coin("aa", 1).id, "aa:1");
    });

    test("is the key image when there is one", () {
      expect(coin("aa", 0, keyImage: "ki-1").id, "ki-1");
    });

    test("distinguishes two outputs of the same transaction", () {
      expect(coin("aa", 0).id, isNot(coin("aa", 1).id));
    });

    test("does not change when the value changes", () {
      // The previous implementation compared stored records to outputs on value
      // and address as well as position, so any drift detached the two.
      expect(coin("aa", 1, value: 1000).id, coin("aa", 1, value: 9999).id);
    });

    test("does not change when the address changes", () {
      final a = Unspent("addr-one", "aa", 1000, 1, null);
      final b = Unspent("addr-two", "aa", 1000, 1, null);
      expect(a.id, b.id);
    });

    test("does not change when isChange or confirmations change", () {
      final c = coin("aa", 1);
      final before = c.id;
      c.isChange = true;
      c.confirmations = 7;
      expect(c.id, before);
    });
  });

  group("AllCoinSelection", () {
    const selection = AllCoinSelection();

    test("allows every output", () {
      expect(selection.allows(coin("aa", 0)), isTrue);
      expect(selection.allows(coin("bb", 3)), isTrue);
    });

    test("allows an output it has never seen", () {
      // This is the whole difference from an enumerated selection: a coin
      // received after the selection was made must still be spendable.
      expect(selection.allows(coin("received-later", 0)), isTrue);
    });

    test("every const instance is the same instance", () {
      // It carries no state, so callers can compare against a const literal --
      // which several of them do -- without the class needing value equality.
      expect(const AllCoinSelection(), same(const AllCoinSelection()));
    });
  });

  group("SpecificCoinSelection", () {
    test("allows only the listed ids", () {
      final selection = SpecificCoinSelection({"aa:0", "bb:1"});
      expect(selection.allows(coin("aa", 0)), isTrue);
      expect(selection.allows(coin("bb", 1)), isTrue);
      expect(selection.allows(coin("cc", 2)), isFalse);
    });

    test("allows nothing when empty", () {
      expect(SpecificCoinSelection(const <String>{}).allows(coin("aa", 0)), isFalse);
    });

    test("excludes an output it has never seen", () {
      final selection = SpecificCoinSelection({"aa:0"});
      expect(selection.allows(coin("received-later", 0)), isFalse);
    });

    test("survives a wholesale replacement of every Unspent instance", () {
      // Refreshing the output list replaces every instance, and transaction
      // creation triggers that refresh after the selection was made. Holding
      // ids rather than instances is what makes the selection outlive it.
      final before = coin("aa", 0);
      final selection = SpecificCoinSelection({before.id});

      final after = coin("aa", 0);
      expect(identical(before, after), isFalse);
      expect(selection.allows(after), isTrue);
    });

    test("matches a Monero output on its key image", () {
      final selection = SpecificCoinSelection({"ki-1"});
      expect(selection.allows(coin("aa", 0, keyImage: "ki-1")), isTrue);
      expect(selection.allows(coin("aa", 0, keyImage: "ki-2")), isFalse);
    });

    test("holds exactly the ids it was given, whatever the order", () {
      // Asserted on the set rather than through ==, which this class does not
      // define: what anything downstream reads is the ids, and comparing two
      // selections is not something the flow does.
      expect(SpecificCoinSelection(["aa:0", "bb:1"]).ids, {"bb:1", "aa:0"});
    });

    test("drops a duplicated id", () {
      expect(SpecificCoinSelection(["aa:0", "aa:0"]).ids, hasLength(1));
    });

    test("rejects mutation of the id set after construction", () {
      final selection = SpecificCoinSelection({"aa:0"});
      expect(() => selection.ids.add("bb:1"), throwsUnsupportedError);
    });
  });
}
