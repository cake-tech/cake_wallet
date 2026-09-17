import "package:cw_core/crypto_currency.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_solana/solana_client.dart";
import "package:cw_solana/solana_exceptions.dart";
import "package:cw_solana/solana_wallet.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("currencyForRawAmount", () {
    test("keeps the stored token when its decimals match the mint", () {
      final jup = SPLToken(
        name: "Jupiter",
        symbol: "JUP",
        mint: "jup",
        mintAddress: "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN",
        decimal: 6,
      );

      expect(SolanaWalletClient.currencyForRawAmount(jup, 6), same(jup));
    });

    test("prefers the mint decimals when the stored token disagrees", () {
      final staleJup = SPLToken(
        name: "Jupiter",
        symbol: "JUP",
        mint: "jup",
        mintAddress: "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN",
        decimal: 0,
      );

      final resolved = SolanaWalletClient.currencyForRawAmount(staleJup, 6);

      expect(resolved.decimals, 6);
      expect(resolved.title, "JUP");
      expect(resolved, isNot(same(staleJup)));
    });

    test("falls back to a placeholder title when the token is unknown", () {
      final resolved = SolanaWalletClient.currencyForRawAmount(null, 8);

      expect(resolved.decimals, 8);
      expect(resolved.title, "TOKEN");
      expect(resolved.name, "token");
    });

    test("always reports the mint decimals", () {
      for (final decimals in [0, 1, 6, 8, 9, 18]) {
        expect(SolanaWalletClient.currencyForRawAmount(null, decimals).decimals, decimals);
      }
    });
  });

  group("resolveTransactionCurrency", () {
    final realUsdc = SPLToken(
      name: "USD Coin",
      symbol: "USDC",
      mint: "usdc",
      mintAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
      decimal: 6,
    );

    final scamUsdc = SPLToken(
      name: "USD Coin",
      symbol: "USDC",
      mint: "usdc",
      mintAddress: "scamMintAddressClaimingTheUsdcSymbol",
      decimal: 9,
    );

    test("picks the requested mint even when another token claims the symbol", () {
      final resolved = SolanaWalletBase.resolveTransactionCurrency(realUsdc, [scamUsdc, realUsdc]);

      expect(resolved, same(realUsdc));
      expect((resolved as SPLToken).mintAddress, realUsdc.mintAddress);
    });

    test("picks the scam mint only when the scam mint is the one requested", () {
      final resolved = SolanaWalletBase.resolveTransactionCurrency(scamUsdc, [scamUsdc, realUsdc]);

      expect(resolved, same(scamUsdc));
    });

    test("throws when the requested mint is not in the wallet", () {
      expect(
        () => SolanaWalletBase.resolveTransactionCurrency(realUsdc, [scamUsdc]),
        throwsA(isA<Exception>()),
      );
    });

    test("throws on ambiguity when a symbol lookup matches two tokens", () {
      expect(
        () => SolanaWalletBase.resolveTransactionCurrency(
          CryptoCurrency(name: "usdc", title: "USDC", decimals: 6, tag: "SOL"),
          [scamUsdc, realUsdc],
        ),
        throwsA(isA<SolanaAmbiguousTokenSymbolException>()),
      );
    });

    test("resolves a native currency by title and tag", () {
      expect(
        SolanaWalletBase.resolveTransactionCurrency(
            CryptoCurrency.sol, [CryptoCurrency.sol, realUsdc]),
        same(CryptoCurrency.sol),
      );
    });
  });
}
