import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Dash is P2PKH-only, and its X-prefixed addresses match none of bitcoin_base's
  // hardcoded address regexes, so addressTypeFromStr must special-case DashNetwork
  // rather than fall through to P2wpkhAddress (which throws on Dash).
  const dashAddress = "Xs8xnigGeN1FG9fZfWJFHhJaCg5oxAUmQU";

  test('classifies a dash address as P2PKH', () {
    final address = addressTypeFromStr(dashAddress, DashNetwork.mainnet);

    expect(address, isA<P2pkhAddress>());
    expect(address.toAddress(DashNetwork.mainnet), dashAddress);
  });

  test('derives the electrum scripthash of a dash address', () {
    // Matches the value the cipig ElectrumX server accepts for this address.
    expect(
      scriptHashOfAddress(dashAddress, DashNetwork.mainnet),
      "06c4fee7ad2321d04d96f97ea46104a6f7999269a48fc79f9baf03a4786d30cd",
    );
  });
}
