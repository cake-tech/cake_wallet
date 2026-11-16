import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const btcBalance = CurrencyPickerBalance(amount: "0.5 BTC");
  const usdcBalance = CurrencyPickerBalance(amount: "100 USDC");

  Erc20Token usdcToken({required String contractAddress, required String tag}) => Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: contractAddress,
        decimal: 6,
        tag: tag,
      );

  group("balanceForAsset", () {
    test("finds the balance stored under the same currency", () {
      expect(balanceForAsset({CryptoCurrency.btc: btcBalance}, CryptoCurrency.btc), btcBalance);
    });

    test("matches a listed currency to the wallet token with the same title and tag", () {
      final token = usdcToken(contractAddress: "0xa0b8", tag: "ETH");

      expect(balanceForAsset({token: usdcBalance}, CryptoCurrency.usdc), usdcBalance);
    });

    test("does not show the on-chain BTC balance for Lightning", () {
      expect(balanceForAsset({CryptoCurrency.btc: btcBalance}, CryptoCurrency.btcln), isNull);
    });

    test("does not match the same token on another chain", () {
      final token = usdcToken(contractAddress: "0x8335", tag: "BASE");

      expect(balanceForAsset({token: usdcBalance}, CryptoCurrency.usdc), isNull);
    });

    test("returns nothing when two balances share the title and tag", () {
      final balances = {
        usdcToken(contractAddress: "0xa0b8", tag: "ETH"): usdcBalance,
        usdcToken(contractAddress: "0xdead", tag: "ETH"): btcBalance,
      };

      expect(balanceForAsset(balances, CryptoCurrency.usdc), isNull);
    });

    test("matches tokens by contract address regardless of case", () {
      final stored = usdcToken(contractAddress: "0xA0B8", tag: "ETH");
      final picked = usdcToken(contractAddress: "0xa0b8", tag: "ETH");

      expect(balanceForAsset({stored: usdcBalance}, picked), usdcBalance);
    });
  });
}
