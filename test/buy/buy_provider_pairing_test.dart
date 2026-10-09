import "package:cake_wallet/buy/dfx/dfx_buy_provider.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockWallet extends Mock implements WalletBase {}

void main() {
  // OP Mainnet, which DFX's asset list names "Optimism"
  const opChainId = 10;
  // Ink, which DFX's asset list does not name
  const inkChainId = 57073;

  // Same title as Ethereum's ETH, so a symbol match alone would pair it with Ethereum
  const opNative = CryptoCurrency(
    title: "ETH",
    tag: "OETH",
    name: "evm$opChainId",
    raw: EvmNativeCurrencies.addedNetworkRawOffset + opChainId,
    decimals: 18,
  );

  const inkNative = CryptoCurrency(
    title: "ETH",
    tag: "INK",
    name: "evm$inkChainId",
    raw: EvmNativeCurrencies.addedNetworkRawOffset + inkChainId,
    decimals: 18,
  );

  late _MockWallet wallet;
  late DFXBuyProvider dfx;

  setUp(() {
    EvmNativeCurrencies.register(opChainId, opNative, WalletType.evm);
    EvmNativeCurrencies.register(inkChainId, inkNative, WalletType.evm);
    wallet = _MockWallet();
    dfx = DFXBuyProvider(wallet: wallet);
  });

  tearDown(() {
    EvmNativeCurrencies.unregister(opChainId);
    EvmNativeCurrencies.unregister(inkChainId);
  });

  test("an added network's ETH on chain 10 pairs with DFX through its Optimism code", () {
    when(() => wallet.type).thenReturn(WalletType.evm);
    when(() => wallet.currency).thenReturn(opNative);

    expect(dfx.addedEvmNetworkCode(opNative), "Optimism");
    expect(dfx.isPairSupported(opNative, FiatCurrency.eur, true), isTrue);
    expect(dfx.isPairSupported(opNative, FiatCurrency.eur, false), isTrue);
    expect(dfx.blockchain, "Optimism");
  });

  test("an added network DFX has no code for is refused", () {
    when(() => wallet.type).thenReturn(WalletType.evm);
    when(() => wallet.currency).thenReturn(inkNative);

    expect(dfx.addedEvmNetworkCode(inkNative), isNull);
    expect(dfx.supportsCurrencyNetwork(inkNative), isFalse);
    expect(dfx.isPairSupported(inkNative, FiatCurrency.eur, true), isFalse);
    expect(dfx.isPairSupported(inkNative, FiatCurrency.eur, false), isFalse);
    expect(() => dfx.blockchain, throwsException);
  });

  test("a wallet on a network DFX has no code for offers no other asset either", () {
    when(() => wallet.type).thenReturn(WalletType.evm);
    when(() => wallet.currency).thenReturn(inkNative);

    expect(dfx.supportsCurrencyNetwork(CryptoCurrency.eth), isFalse);
    expect(dfx.isPairSupported(CryptoCurrency.eth, FiatCurrency.eur, true), isFalse);
    expect(dfx.isPairSupported(CryptoCurrency.eth, FiatCurrency.eur, false), isFalse);
  });

  test("the fiat rule still applies on a coded added network", () {
    when(() => wallet.type).thenReturn(WalletType.evm);
    when(() => wallet.currency).thenReturn(opNative);

    expect(dfx.isPairSupported(opNative, FiatCurrency.usd, true), isFalse);
    expect(dfx.isPairSupported(opNative, FiatCurrency.usd, false), isFalse);
  });

  test("Ethereum's ETH keeps its symbol and tag pairing", () {
    when(() => wallet.type).thenReturn(WalletType.ethereum);

    expect(dfx.addedEvmNetworkCode(CryptoCurrency.eth), isNull);
    expect(dfx.supportsCurrencyNetwork(CryptoCurrency.eth), isTrue);
    expect(dfx.isPairSupported(CryptoCurrency.eth, FiatCurrency.eur, true), isTrue);
    expect(dfx.isPairSupported(CryptoCurrency.eth, FiatCurrency.usd, true), isFalse);
    expect(dfx.blockchain, "Ethereum");
  });
}
