import "package:cw_evm/history/etherscan_history_provider.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("EtherscanHistoryProvider.covers", () {
    test("needs the API key", () {
      expect(EtherscanHistoryProvider(apiKey: "").covers(10), isFalse);
      expect(EtherscanHistoryProvider(apiKey: "k").covers(10), isTrue);
    });

    test("is limited to the chains Etherscan lists", () {
      // X Layer (196) is not one of the 63
      expect(EtherscanHistoryProvider(apiKey: "k").covers(196), isFalse);
    });
  });
}
