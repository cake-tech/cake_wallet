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

    group("uniqueEvmTokensForSwap", () {
      // The same contract address deployed on two chains
      const sharedContract = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";

      test("keeps a contract on two chains as two tokens", () {
        final ethereumToken = Erc20Token(
          name: "Ethereum Token",
          symbol: "ETK",
          contractAddress: sharedContract,
          decimal: 6,
          chainId: 1,
        );
        final opToken = Erc20Token(
          name: "OP Token",
          symbol: "OTK",
          contractAddress: sharedContract.toLowerCase(),
          decimal: 6,
          chainId: 10,
        );

        final tokens = TokenUtilities.uniqueEvmTokensForSwap({}, [ethereumToken, opToken]);

        expect(tokens, hasLength(2));
        expect(tokens[0], same(ethereumToken));
        expect(tokens[1], same(opToken));
      });

      test("drops a user token that repeats a default on the same chain", () {
        final defaultToken = Erc20Token(
          name: "Default Token",
          symbol: "DTK",
          contractAddress: sharedContract,
          decimal: 6,
        );
        final userCopy = Erc20Token(
          name: "User Copy",
          symbol: "UCP",
          contractAddress: sharedContract.toLowerCase(),
          decimal: 6,
          chainId: 137,
        );

        final tokens = TokenUtilities.uniqueEvmTokensForSwap({
          137: [defaultToken],
        }, [
          userCopy,
        ]);

        expect(tokens, hasLength(1));
        expect(tokens.single, same(defaultToken));
      });
    });
  });
}
