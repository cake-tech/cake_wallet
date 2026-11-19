import "package:cw_core/crypto_currency.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/tron_token.dart";
import "package:cw_tron/default_tron_tokens.dart";
import "package:cw_tron/tron_wallet.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("resolveTransactionCurrency", () {
    final realUsdt = TronToken(
      name: "Tether USD",
      symbol: "USDT",
      contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
      decimal: 6,
    );

    final scamUsdt = TronToken(
      name: "Tether USD",
      symbol: "USDT",
      contractAddress: "TScamContractClaimingTheUsdtSymbol",
      decimal: 6,
    );

    test("picks the requested contract even when another token claims the symbol first", () {
      final resolved = TronWalletBase.resolveTransactionCurrency(
        TronToken.copyWith(realUsdt),
        [CryptoCurrency.trx, scamUsdt, realUsdt],
      );

      expect(resolved, same(realUsdt));
    });

    test("throws when the requested contract is not in the wallet", () {
      expect(
        () => TronWalletBase.resolveTransactionCurrency(realUsdt, [CryptoCurrency.trx, scamUsdt]),
        throwsA(isA<TransactionGenerationException>()),
      );
    });

    test("resolves a native currency by title and tag", () {
      final resolved = TronWalletBase.resolveTransactionCurrency(
        CryptoCurrency.trx,
        [CryptoCurrency.trx, scamUsdt, realUsdt],
      );

      expect(resolved, same(CryptoCurrency.trx));
    });

    test("resolves a currency without a contract to the default token by title and tag", () {
      final resolved = TronWalletBase.resolveTransactionCurrency(
        CryptoCurrency.usdttrc20,
        [CryptoCurrency.trx, ...DefaultTronTokens().initialTronTokens],
      );

      expect((resolved as TronToken).contractAddress, DefaultTronTokens().usdt.contractAddress);
    });
  });
}
