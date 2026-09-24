import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/message_signing.dart";
import "package:flutter_test/flutter_test.dart";

BitcoinAddressRecord _record(String address, {BitcoinAddressType type = SegwitAddresType.p2wpkh}) =>
    BitcoinAddressRecord(
      address,
      index: 0,
      type: type,
      network: BitcoinNetwork.mainnet,
    );

void main() {
  group("resolveMessageSigningAddress", () {
    test("returns null when address is null", () {
      final result = resolveMessageSigningAddress(
        address: null,
        allAddresses: [_record("bc1qknown")],
      );
      expect(result, isNull);
    });

    test("returns the matching record when the address is in the list", () {
      final known = _record("bc1qknown");
      final result = resolveMessageSigningAddress(
        address: "bc1qknown",
        allAddresses: [known, _record("bc1qother")],
      );
      expect(result, same(known));
    });

    test("throws UnsupportedError when address is not in the list", () {
      expect(
        () => resolveMessageSigningAddress(
          address: "sp1qqgste7k9hx0qvc7vi3xaqj9vc7g8x2example",
          allAddresses: [_record("bc1qknown")],
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            "message",
            "Cannot sign message with this address",
          ),
        ),
      );
    });

    test("throws UnsupportedError for a Taproot address", () {
      expect(
        () => resolveMessageSigningAddress(
          address: "bc1ptaproot",
          allAddresses: [_record("bc1ptaproot", type: SegwitAddresType.p2tr)],
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            "message",
            "Cannot sign message with Taproot address",
          ),
        ),
      );
    });
  });
}
