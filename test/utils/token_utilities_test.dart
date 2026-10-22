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

      test("resolves new Tron stablecoin contracts", () {
        expect(
          TokenUtilities.findTronTokenContract(CryptoCurrency.usd1Trx),
          "TPFqcBAaaUMCSVRCqPaQ9QnzKhmuoLR6Rc",
        );
        expect(
          TokenUtilities.findTronTokenContract(CryptoCurrency.usddTrx),
          "TXDk8mbtRbXeYuMNS83CfKPaYYT8XWv9Hz",
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

      test("resolves disabled defaults for new EVM stablecoins", () {
        const contracts = {
          CryptoCurrency.usdeEth: "0x4c9edd5852cd905f086c759e8383e09bff1e68b3",
          CryptoCurrency.usdsEth: "0xdc035d45d973e3ec169d2276ddab16f1e407384f",
          CryptoCurrency.usd1Eth: "0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d",
          CryptoCurrency.usdgEth: "0xe343167631d89b6ffc58b88d6b7fb0228795491d",
          CryptoCurrency.pyusdEth: "0x6c3ea9036406852006290770bedfcaba0e23a0e8",
          CryptoCurrency.rlusdEth: "0x8292bb45bf1ee4d140127049757c2e0ff06317ed",
          CryptoCurrency.eurcEth: "0x1abaea1f7c830bd89acc67ec4af516284b1bc33c",
          CryptoCurrency.usd1Bsc: "0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d",
          CryptoCurrency.eurcBase: "0x60a3e35cc302bfa44cb288bc5a4f316fdb1adb42",
        };
        for (final entry in contracts.entries) {
          final token = TokenUtilities.findErc20TokenForSwap(entry.key);
          expect(token?.contractAddress, entry.value, reason: entry.key.name);
          expect(token?.decimal, entry.key.decimals, reason: entry.key.name);
          expect(token?.enabled, isFalse, reason: entry.key.name);
        }
      });
    });

    test("distinguishes BSC stablecoins from native BNB", () {
      expect(TokenUtilities.isNativeToken(CryptoCurrency.usd1Bsc), isFalse);
      expect(TokenUtilities.isNativeToken(CryptoCurrency.bnb), isTrue);
    });
  });
}
