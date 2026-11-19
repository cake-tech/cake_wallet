import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_evm/evm_chain_default_tokens.dart";
import "package:cw_evm/evm_chain_wallet.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("resolveTransactionCurrency", () {
    final realUsdt = Erc20Token(
      name: "Tether USD",
      symbol: "USDT",
      contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
      decimal: 6,
      tag: "ETH",
    );

    final scamUsdt = Erc20Token(
      name: "Tether USD",
      symbol: "USDT",
      contractAddress: "0xscamContractClaimingTheUsdtSymbol",
      decimal: 6,
      tag: "ETH",
    );

    test("picks the requested contract even when another token claims the symbol first", () {
      final resolved = EVMChainWalletBase.resolveTransactionCurrency(
        Erc20Token.copyWith(realUsdt),
        [CryptoCurrency.eth, scamUsdt, realUsdt],
      );

      expect(resolved, same(realUsdt));
    });

    test("matches the contract regardless of case", () {
      final checksummedUsdt = Erc20Token(
        name: "Tether USD",
        symbol: "USDT",
        contractAddress: "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",
        decimal: 6,
        tag: "ARB",
      );
      final storedUsdt = Erc20Token(
        name: "Tether USD",
        symbol: "USDT",
        contractAddress: "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9",
        decimal: 6,
        tag: "ARB",
      );

      final resolved = EVMChainWalletBase.resolveTransactionCurrency(
        storedUsdt,
        [CryptoCurrency.arbEth, checksummedUsdt],
      );

      expect(resolved, same(checksummedUsdt));
    });

    test("throws when the requested contract is not in the wallet", () {
      expect(
        () => EVMChainWalletBase.resolveTransactionCurrency(
          realUsdt,
          [CryptoCurrency.eth, scamUsdt],
        ),
        throwsA(isA<BadCurrencyException>()),
      );
    });

    test("throws when the requested contract is tagged for another chain", () {
      expect(
        () => EVMChainWalletBase.resolveTransactionCurrency(
          Erc20Token.copyWith(realUsdt, tag: "BASE"),
          [CryptoCurrency.eth, realUsdt],
        ),
        throwsA(isA<BadCurrencyException>()),
      );
    });

    test("resolves a native currency by title and tag", () {
      final resolved = EVMChainWalletBase.resolveTransactionCurrency(
        CryptoCurrency.eth,
        [CryptoCurrency.eth, scamUsdt, realUsdt],
      );

      expect(resolved, same(CryptoCurrency.eth));
    });

    test("resolves dEuro savings' currency to the default dEuro token by title and tag", () {
      final resolved = EVMChainWalletBase.resolveTransactionCurrency(
        CryptoCurrency.deuro,
        [CryptoCurrency.eth, ...EVMChainDefaultTokens.getDefaultTokensByChainId(1)],
      );

      expect(
        (resolved as Erc20Token).contractAddress,
        "0xba3f535bbcccca2a154b573ca6c5a49baae0a3ea",
      );
    });

    test("resolves the swap's untagged ARB to Arbitrum's ARB token", () {
      final resolved = EVMChainWalletBase.resolveTransactionCurrency(
        CryptoCurrency.arb,
        [CryptoCurrency.arbEth, ...EVMChainDefaultTokens.getDefaultTokensByChainId(42161)],
      );

      expect(
        (resolved as Erc20Token).contractAddress,
        "0x912ce59144191c1204e64559fe8253a0e49e6548",
      );
    });
  });
}
