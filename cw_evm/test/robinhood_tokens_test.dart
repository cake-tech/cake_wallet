import "package:cw_core/currency_groups.dart";
import "package:cw_evm/history/moralis_history_provider.dart";
import "package:cw_evm/tokens/robinhood_tokens.dart";
import "package:cw_evm/utils/evm_chain_utils.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("RobinhoodTokens integrity", () {
    final tokens = RobinhoodTokens.tokens;
    final addressPattern = RegExp(r"^0x[0-9a-f]{40}$");

    test("token list is non-empty", () => expect(tokens.isNotEmpty, isTrue));

    test("every contract address is a lowercased 0x-prefixed 40-hex-char address", () {
      for (final token in tokens) {
        expect(
          addressPattern.hasMatch(token.contractAddress),
          isTrue,
          reason: "bad address for ${token.symbol}: ${token.contractAddress}",
        );
      }
    });

    test("every token has a non-empty name and symbol", () {
      for (final token in tokens) {
        expect(token.name.trim(), isNotEmpty, reason: "empty name for ${token.contractAddress}");
        expect(
          token.symbol.trim(),
          isNotEmpty,
          reason: "empty symbol for ${token.contractAddress}",
        );
      }
    });

    test("every decimal is within the 0..18 range", () {
      for (final token in tokens) {
        expect(
          token.decimal,
          inInclusiveRange(0, 18),
          reason: "bad decimal for ${token.symbol}: ${token.decimal}",
        );
      }
    });

    test("no duplicate contract addresses", () {
      final seen = <String>{};
      for (final token in tokens) {
        final addr = token.contractAddress.toLowerCase();
        expect(seen.add(addr), isTrue, reason: "duplicate address $addr (${token.symbol})");
      }
    });

    test("USDG is the 6-decimal stablecoin and is enabled by default", () {
      final usdg = tokens.firstWhere((t) => t.symbol == "USDG");
      expect(usdg.decimal, 6);
      expect(usdg.enabled, isTrue);
    });

    test("tokenized stock tokens exist and ship disabled", () {
      final stocks = tokens.where((t) => t.groups.contains(CurrencyGroups.tokenizedStock)).toList();
      expect(stocks, isNotEmpty);
      expect(stocks.every((t) => !t.enabled), isTrue);
    });
  });

  group("EVMChainUtils Robinhood chain params", () {
    test("Moralis does not index Robinhood, so token discovery skips it", () {
      expect(MoralisHistoryProvider.supportedChainIds, isNot(contains(4663)));
    });

    test("Robinhood is an Orbit chain with no priority fee", () {
      expect(EVMChainUtils.hasPriorityFee(4663), isFalse);
    });

    test("Robinhood default token tag is ROB and fee currency is ETH", () {
      expect(EVMChainUtils.getDefaultTokenTag(4663), "ROB");
      expect(EVMChainUtils.getFeeCurrency(4663), "ETH");
    });
  });
}
