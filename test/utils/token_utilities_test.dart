import "package:cake_wallet/utils/token_utilities.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/tron_token.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("TokenUtilities", () {
    group("findTronTokenContract", () {
      test("returns the contract from a TronToken instance", () {
        final token = TronToken(
          name: "Test Token",
          symbol: "TST",
          contractAddress: "TContractAddress123",
          decimal: 6,
        );

        expect(TokenUtilities.findTronTokenContract(token), "TContractAddress123");
      });

      test("resolves a bare currency from the default token list", () {
        expect(
          TokenUtilities.findTronTokenContract(CryptoCurrency.usdttrc20),
          "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
        );
      });

      test("returns null for native TRX", () {
        expect(TokenUtilities.findTronTokenContract(CryptoCurrency.trx), null);
      });

      test("does not resolve a token from another network", () {
        expect(TokenUtilities.findTronTokenContract(CryptoCurrency.usdtSol), null);
      });
    });

    group("findSolanaTokenMint", () {
      test("returns the mint from an SPLToken instance", () {
        final token = SPLToken(
          name: "Test Token",
          symbol: "TST",
          mintAddress: "MintAddress123",
          decimal: 6,
          mint: "tst",
        );

        expect(TokenUtilities.findSolanaTokenMint(token), "MintAddress123");
      });

      test("resolves a bare currency from the default token list", () {
        expect(
          TokenUtilities.findSolanaTokenMint(CryptoCurrency.usdtSol),
          "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB",
        );
      });

      test("returns null for native SOL", () {
        expect(TokenUtilities.findSolanaTokenMint(CryptoCurrency.sol), null);
      });

      test("does not resolve a token from another network", () {
        expect(TokenUtilities.findSolanaTokenMint(CryptoCurrency.usdttrc20), null);
      });
    });

    group("findErc20TokenForSwap", () {
      test("returns the same instance for an Erc20Token", () {
        final token = Erc20Token(
          name: "Test Token",
          symbol: "TST",
          contractAddress: "0x0000000000000000000000000000000000000001",
          decimal: 18,
        );

        expect(TokenUtilities.findErc20TokenForSwap(token), same(token));
      });

      test("returns null for native ETH", () {
        expect(TokenUtilities.findErc20TokenForSwap(CryptoCurrency.eth), null);
      });
    });

    group("tokenAddress", () {
      test("returns the contract or mint of each token type", () {
        final erc20 = Erc20Token(
          name: "USD Coin",
          symbol: "USDC",
          contractAddress: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
          decimal: 6,
        );
        final tron = TronToken(
          name: "Tether USD",
          symbol: "USDT",
          contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
          decimal: 6,
        );
        final spl = SPLToken(
          name: "USD Coin",
          symbol: "USDC",
          mintAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
          decimal: 6,
          mint: "usdc",
        );

        expect(TokenUtilities.tokenAddress(erc20), "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913");
        expect(TokenUtilities.tokenAddress(tron), "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t");
        expect(TokenUtilities.tokenAddress(spl), "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v");
      });

      test("returns null for native coins", () {
        expect(TokenUtilities.tokenAddress(CryptoCurrency.eth), null);
        expect(TokenUtilities.tokenAddress(CryptoCurrency.trx), null);
      });
    });
  });
}
