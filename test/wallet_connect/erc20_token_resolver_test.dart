import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";
import "stubs.dart";
import "wc_service_rig.dart";

class _TokenEvm extends Fake implements EVM {
  final walletTokens = <Erc20Token>[];
  final onChain = <String, Erc20Token>{};

  @override
  List<Erc20Token> getERC20Currencies(WalletBase wallet) => walletTokens;

  @override
  List<Erc20Token> getDefaultTokensByChainId(int chainId) => const [];

  @override
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress) async =>
      onChain[contractAddress];
}

class _FiatSettings extends Fake implements SettingsStore {
  @override
  FiatCurrency fiatCurrency = FiatCurrency.usd;
}

class _AppStore extends Fake implements AppStore {
  @override
  AnyWallet? wallet = RigWallet("Wallet A", address: _wallet, privateKey: "", chains: const []);

  @override
  final SettingsStore settingsStore = _FiatSettings();
}

const _wallet = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";
const _contract = "0x1111111111111111111111111111111111111111";
const _recipient = "0x3333333333333333333333333333333333333333";

void main() {
  late _TokenEvm evmProxy;
  late _AppStore appStore;
  late Erc20TokenResolver resolver;

  setUp(() {
    S.current = const S();
    evmProxy = _TokenEvm();
    evm = evmProxy;
    appStore = _AppStore();
    resolver = Erc20TokenResolver(appStore);
  });

  Erc20Token token({int decimal = 6, String name = "USD Coin", String symbol = "USDC"}) =>
      Erc20Token(name: name, symbol: symbol, contractAddress: _contract, decimal: decimal);

  group("the decimals a contract reports", () {
    const int64Max = 9223372036854775807;

    for (final decimal in [78, 255, 5000000, int64Max, -1]) {
      test("$decimal decimals leave the token unresolved", () async {
        evmProxy.onChain[_contract] = token(decimal: decimal);

        expect(await resolver.resolve(_contract), isNull);
      });
    }

    for (final decimal in [0, 18, 77]) {
      test("$decimal decimals resolve", () async {
        evmProxy.onChain[_contract] = token(decimal: decimal);

        expect((await resolver.resolve(_contract))?.decimal, decimal);
      });
    }

    test("a token in the wallet's own list is held to the same bound", () async {
      evmProxy.walletTokens.add(token(decimal: 255));

      expect(await resolver.resolve(_contract), isNull);
    });

    test("a transfer of such a token shows the raw amount and warns", () async {
      evmProxy.onChain[_contract] = token(decimal: 100);

      final decoded = await Erc20Decoder(resolver).decode(
        calldata: EvmCalldata.parse("0xa9059cbb${wordAddr(_recipient)}${wordInt(123)}")!,
        contractAddress: _contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(rowLines(decoded!.rows), [
        row(S.current.wc_token, _contract),
        row(S.current.wc_amount, "123 0x1111…1111"),
        row(S.current.to, _recipient),
      ]);
      expect(decoded.warnings, [S.current.wc_warning_unknown_token]);
    });
  });

  group("the name and symbol a contract reports", () {
    test("are cut to 64 characters", () {
      final long = token(name: "N" * 200, symbol: "s" * 200);
      final symbol = resolver.symbolOrShort(long, _contract);

      expect(symbol, "${"S" * 64}…");
      expect(resolver.displayName(long, "USDC"), "${"N" * 64}… (USDC)");
      expect(resolver.amountText(BigInt.from(2500000), long, _contract), "2.5 ${"S" * 64}…");
    });

    test("of 64 characters are shown whole", () {
      final exact = token(name: "N" * 64, symbol: "s" * 64);

      expect(resolver.symbolOrShort(exact, _contract), "S" * 64);
      expect(resolver.displayName(exact, "USDC"), "${"N" * 64} (USDC)");
    });

    test("are not cut in the middle of a character", () {
      final emoji = token(name: "🦄" * 100, symbol: "🦄" * 100);

      expect(resolver.symbolOrShort(emoji, _contract), "${"🦄" * 64}…");
      expect(resolver.displayName(emoji, "USDC"), "${"🦄" * 64}… (USDC)");
    });
  });

  test("a fiat value comes from the store the resolver was given", () {
    final prices = FiatConversionStore(appStore.settingsStore)..prices[CryptoCurrency.eth] = 2000;
    final priced = Erc20TokenResolver(appStore, fiatConversionStore: prices);

    expect(priced.fiatFor(CryptoCurrency.eth, "1.5"), "~ 3,000.00 USD");
    expect(priced.fiatFor(CryptoCurrency.maticpoly, "1.5"), isNull);
    expect(resolver.fiatFor(CryptoCurrency.eth, "1.5"), isNull);
  });
}
