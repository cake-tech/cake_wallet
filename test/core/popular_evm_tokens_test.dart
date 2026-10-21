import "package:cake_wallet/core/popular_evm_tokens.dart";
import "package:flutter_test/flutter_test.dart";

PopularEvmToken _token(String symbol, String address, {int decimals = 18}) => PopularEvmToken(
      name: "$symbol token",
      symbol: symbol,
      contractAddress: address,
      decimals: decimals,
    );

List<String> _symbols(List<PopularEvmToken> tokens) => tokens.map((token) => token.symbol).toList();

void main() {
  group("PopularEvmTokens.pick", () {
    test("takes the wrapped native coin first, then the popular list in order, up to four", () {
      // Shaped like Avalanche's CoinGecko list
      final tokens = [
        _token("JOE", "0x01"),
        _token("WBTC", "0x02", decimals: 8),
        _token("DAI", "0x03"),
        _token("USDt", "0x04", decimals: 6),
        _token("USDC", "0x05", decimals: 6),
        _token("WAVAX", "0x06"),
      ];

      final picked = PopularEvmTokens.pick(tokens, "AVAX");

      expect(_symbols(picked), ["WAVAX", "USDC", "USDt", "DAI"]);
      expect(picked.map((token) => token.contractAddress), ["0x06", "0x05", "0x04", "0x03"]);
    });

    test("a symbol listed more than once is skipped, the next popular one takes its place", () {
      // Shaped like Cronos' CoinGecko list, two USDC and two WETH
      final tokens = [
        _token("WCRO", "0x10"),
        _token("USDC", "0x11", decimals: 6),
        _token("USDC", "0x12", decimals: 6),
        _token("USDT", "0x13", decimals: 6),
        _token("DAI", "0x14"),
        _token("WETH", "0x15"),
        _token("WETH", "0x16"),
        _token("WBTC", "0x17", decimals: 8),
      ];

      expect(_symbols(PopularEvmTokens.pick(tokens, "CRO")), ["WCRO", "USDT", "DAI", "WBTC"]);
    });

    test("only one Tether is taken when a chain lists both USDT and USDT0", () {
      final tokens = [
        _token("WMON", "0x20"),
        _token("USDT0", "0x21", decimals: 6),
        _token("USDT", "0x22", decimals: 6),
        _token("WETH", "0x23"),
      ];

      expect(_symbols(PopularEvmTokens.pick(tokens, "MON")), ["WMON", "USDT", "WETH"]);
    });

    test("an ETH network gets WETH once, not twice", () {
      final tokens = [
        _token("WETH", "0x30"),
        _token("USDC", "0x31", decimals: 6),
      ];

      expect(_symbols(PopularEvmTokens.pick(tokens, "ETH")), ["WETH", "USDC"]);
    });

    test("a chain with none of the popular tokens gets none", () {
      expect(PopularEvmTokens.pick([_token("FOO", "0x40")], "BAR"), isEmpty);
      expect(PopularEvmTokens.pick([], "BAR"), isEmpty);
    });
  });
}
