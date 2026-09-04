import "dart:async";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" as mobx;
import "package:mocktail/mocktail.dart";

class _MockBitcoin extends Mock implements Bitcoin {}

class _MockWallet extends Mock implements WalletBase {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _MockWalletInfo extends Mock implements WalletInfo {}

class _MockBalance extends Mock implements Balance {}

class _FakeSettingsStore extends Fake implements SettingsStore {
  _FakeSettingsStore({
    AutoGenerateSubaddressStatus status = AutoGenerateSubaddressStatus.disabled,
  }) : _status = status;

  AutoGenerateSubaddressStatus _status;

  @override
  AutoGenerateSubaddressStatus get autoGenerateSubaddressStatus => _status;

  @override
  set autoGenerateSubaddressStatus(AutoGenerateSubaddressStatus next) {
    _status = next;
  }
}

class _FakePaymentURI extends Fake implements PaymentURI {
  _FakePaymentURI(this.raw);
  final String raw;
  @override
  String toString() => raw;
}

class _TestScope {
  _TestScope({
    WalletType walletType = WalletType.bitcoin,
    CryptoCurrency? walletCurrency,
    bool infoboxDismissed = false,
    bool autoGenerateSubaddress = false,
    Map<CryptoCurrency, Balance>? balances,
    String currentAddress = "addr-current",
    String latestAddress = "",
    Set<String>? hiddenAddresses,
    List<ReceivePageOption> receivePageOptions = const [ReceivePageOption.mainnet],
    AutoGenerateSubaddressStatus autoStatus = AutoGenerateSubaddressStatus.disabled,
  }) : settings = _FakeSettingsStore(status: autoStatus) {
    walletInfo = _MockWalletInfo();
    when(() => walletInfo.type).thenReturn(walletType);
    when(() => walletInfo.name).thenReturn("wallet-a");
    when(() => walletInfo.receiveInfoboxDismissed).thenReturn(infoboxDismissed);
    when(walletInfo.save).thenAnswer((_) async => 0);

    walletAddresses = _MockWalletAddresses();
    when(() => walletAddresses.address).thenReturn(currentAddress);
    when(() => walletAddresses.latestAddress).thenReturn(latestAddress);
    when(() => walletAddresses.hiddenAddresses).thenReturn(hiddenAddresses ?? <String>{});
    when(() => walletAddresses.walletInfo).thenReturn(walletInfo);
    when(() => walletAddresses.receivePageOptions).thenReturn(receivePageOptions);
    when(walletAddresses.saveAddressesInBox).thenAnswer((_) async {});

    wallet = _MockWallet();
    when(() => wallet.type).thenReturn(walletType);
    when(() => wallet.name).thenReturn("wallet-a");
    when(() => wallet.walletAddresses).thenReturn(walletAddresses);
    when(() => wallet.walletInfo).thenReturn(walletInfo);
    when(() => wallet.chainId).thenReturn(null);
    when(() => wallet.currency).thenReturn(walletCurrency ?? _defaultCurrencyForType(walletType));
    when(() => wallet.balance)
        .thenReturn(mobx.ObservableMap<CryptoCurrency, Balance>.of(balances ?? {}));
    when(() => wallet.isEnabledAutoGenerateSubaddress).thenReturn(autoGenerateSubaddress);
    when(wallet.save).thenAnswer((_) async {});
  }

  late final _MockWallet wallet;
  late final _MockWalletAddresses walletAddresses;
  late final _MockWalletInfo walletInfo;
  final _FakeSettingsStore settings;
  final StreamController<WalletBase> _walletChanges = StreamController<WalletBase>.broadcast();

  AddressService build({BitcoinAmountDisplayMode mode = BitcoinAmountDisplayMode.bitcoin}) =>
      AddressService(
        wallet: () => wallet,
        walletChanges: _walletChanges.stream,
        settingsStore: settings,
        amountParsingProxyGetter: () => AmountParsingProxy(mode),
      );

  Future<void> dispose() async {
    await _walletChanges.close();
  }
}

CryptoCurrency _defaultCurrencyForType(WalletType type) {
  switch (type) {
    case WalletType.bitcoin:
      return CryptoCurrency.btc;
    case WalletType.litecoin:
      return CryptoCurrency.ltc;
    case WalletType.monero:
      return CryptoCurrency.xmr;
    case WalletType.wownero:
      return CryptoCurrency.wow;
    case WalletType.solana:
      return CryptoCurrency.sol;
    case WalletType.tron:
      return CryptoCurrency.trx;
    case WalletType.nano:
      return CryptoCurrency.nano;
    case WalletType.banano:
      return CryptoCurrency.banano;
    case WalletType.zano:
      return CryptoCurrency.zano;
    case WalletType.decred:
      return CryptoCurrency.dcr;
    case WalletType.zcash:
      return CryptoCurrency.zec;
    case WalletType.bitcoinCash:
      return CryptoCurrency.bch;
    case WalletType.dogecoin:
      return CryptoCurrency.doge;
    default:
      return CryptoCurrency.btc;
  }
}

void main() {
  Bitcoin? _originalBitcoin;

  setUpAll(() {
    registerFallbackValue(WalletType.bitcoin);
    registerFallbackValue(ReceivePageOption.mainnet);
    _originalBitcoin = bitcoin;
    final b = _MockBitcoin();
    when(() => b.getPayjoinEndpoint(any())).thenReturn("");
    bitcoin = b;
  });

  tearDownAll(() {
    bitcoin = _originalBitcoin;
  });

  late _TestScope scope;

  tearDown(() async {
    await scope.dispose();
  });

  group("chain-agnostic getters", () {
    test("walletType / walletCurrency reflect wallet fields", () {
      scope = _TestScope(walletType: WalletType.monero);
      final service = scope.build();
      addTearDown(service.dispose);

      expect(service.walletType, WalletType.monero);
      expect(service.walletCurrency, CryptoCurrency.xmr);
    });

    test("receivableTokens returns crypto keys from wallet.balance", () {
      scope = _TestScope(
        balances: {
          CryptoCurrency.btc: _MockBalance(),
          CryptoCurrency.eth: _MockBalance(),
        },
      );
      final service = scope.build();
      addTearDown(service.dispose);

      expect(
        service.receivableTokens,
        containsAll([CryptoCurrency.btc, CryptoCurrency.eth]),
      );
    });

    test("isInfoboxDismissed reads wallet.walletInfo.receiveInfoboxDismissed", () {
      scope = _TestScope(infoboxDismissed: true);
      final service = scope.build();
      addTearDown(service.dispose);

      expect(service.isInfoboxDismissed, isTrue);
    });

    test("hasAccounts is true only for Monero and Wownero", () {
      for (final entry in const {
        WalletType.monero: true,
        WalletType.wownero: true,
        WalletType.bitcoin: false,
        WalletType.zcash: false,
        WalletType.solana: false,
      }.entries) {
        scope = _TestScope(walletType: entry.key);
        final service = scope.build();
        expect(service.hasAccounts, entry.value, reason: entry.key.toString());
        service.dispose();
      }
    });

    test("currentAddress reads wallet.walletAddresses.address", () {
      scope = _TestScope(currentAddress: "bc1qabc");
      final service = scope.build();
      addTearDown(service.dispose);

      expect(service.currentAddress, "bc1qabc");
    });

    test("addressTypeOptions reads wallet.walletAddresses.receivePageOptions", () {
      scope = _TestScope(receivePageOptions: const [ReceivePageOption.mainnet]);
      final service = scope.build();
      addTearDown(service.dispose);

      expect(service.addressTypeOptions, const [ReceivePageOption.mainnet]);
    });

    test("selectedAddressType is null for chains outside {bitcoin, litecoin, zcash}", () {
      for (final t in const [
        WalletType.monero,
        WalletType.wownero,
        WalletType.solana,
        WalletType.tron,
        WalletType.nano,
        WalletType.banano,
        WalletType.zano,
        WalletType.decred,
        WalletType.bitcoinCash,
        WalletType.dogecoin,
      ]) {
        scope = _TestScope(walletType: t);
        final service = scope.build();
        expect(service.selectedAddressType, isNull, reason: t.toString());
        service.dispose();
      }
      scope = _TestScope();
    });

    test("currentAccount is null for chains without accounts", () {
      for (final t in const [
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.solana,
        WalletType.zcash,
        WalletType.decred,
      ]) {
        scope = _TestScope(walletType: t);
        final service = scope.build();
        expect(service.currentAccount, isNull, reason: t.toString());
        service.dispose();
      }
      scope = _TestScope();
    });

    test("receivableTokens ignores non-CryptoCurrency balance keys", () {
      scope = _TestScope(
        balances: {
          CryptoCurrency.btc: _MockBalance(),
        },
      );
      final service = scope.build();
      addTearDown(service.dispose);

      expect(service.receivableTokens, [CryptoCurrency.btc]);
    });

    test("receivableTokens is empty when wallet.balance is empty", () {
      scope = _TestScope(balances: {});
      final service = scope.build();
      addTearDown(service.dispose);

      expect(service.receivableTokens, isEmpty);
    });
  });

  group("chain capability flags", () {
    test("canSetLabel is true for electrum, decred, monero, wownero — else false", () {
      const truthy = {
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.bitcoinCash,
        WalletType.dogecoin,
        WalletType.decred,
        WalletType.monero,
        WalletType.wownero,
      };
      const falsy = {
        WalletType.solana,
        WalletType.tron,
        WalletType.nano,
        WalletType.banano,
        WalletType.zano,
        WalletType.zcash,
      };
      for (final t in truthy) {
        scope = _TestScope(walletType: t);
        final service = scope.build();
        expect(service.canSetLabel, isTrue, reason: t.toString());
        service.dispose();
      }
      for (final t in falsy) {
        scope = _TestScope(walletType: t);
        final service = scope.build();
        expect(service.canSetLabel, isFalse, reason: t.toString());
        service.dispose();
      }
    });

    test("isZCashTransparent returns true for non-Zcash wallets", () {
      scope = _TestScope(walletType: WalletType.bitcoin);
      final service = scope.build();
      addTearDown(service.dispose);

      expect(service.isZCashTransparent, isTrue);
    });
  });

  group("auto-generate subaddress", () {
    test("autoGenerateSubaddressStatus reads settings", () {
      scope = _TestScope(autoStatus: AutoGenerateSubaddressStatus.enabled);
      final service = scope.build();
      addTearDown(service.dispose);

      expect(service.autoGenerateSubaddressStatus, AutoGenerateSubaddressStatus.enabled);
    });

    test(
      "isAutoGenerateSubaddressEnabled is true when status != disabled AND not silent payments",
      () {
        scope = _TestScope(
          walletType: WalletType.monero,
          autoStatus: AutoGenerateSubaddressStatus.enabled,
        );
        final service = scope.build();
        addTearDown(service.dispose);

        expect(service.isAutoGenerateSubaddressEnabled, isTrue);
      },
    );

    test("isAutoGenerateSubaddressEnabled is false when status is disabled", () {
      scope = _TestScope(
        walletType: WalletType.monero,
        autoStatus: AutoGenerateSubaddressStatus.disabled,
      );
      final service = scope.build();
      addTearDown(service.dispose);

      expect(service.isAutoGenerateSubaddressEnabled, isFalse);
    });
  });

  group("applyAutoGenerateOverride", () {
    test("no-op when wallet.isEnabledAutoGenerateSubaddress is false", () {
      scope = _TestScope(autoGenerateSubaddress: false, latestAddress: "addr-latest");
      final service = scope.build();
      addTearDown(service.dispose);

      service.applyAutoGenerateOverride();

      verifyNever(() => scope.walletAddresses.address = any());
    });

    test("no-op when latestAddress is empty", () {
      scope = _TestScope(autoGenerateSubaddress: true, latestAddress: "");
      final service = scope.build();
      addTearDown(service.dispose);

      service.applyAutoGenerateOverride();

      verifyNever(() => scope.walletAddresses.address = any());
    });

    test("writes wallet.walletAddresses.address = latestAddress when both conditions hold", () {
      scope = _TestScope(autoGenerateSubaddress: true, latestAddress: "addr-latest");
      final service = scope.build();
      addTearDown(service.dispose);

      service.applyAutoGenerateOverride();

      verify(() => scope.walletAddresses.address = "addr-latest").called(1);
    });
  });

  group("setActiveAddress", () {
    test("writes the address to wallet.walletAddresses.address", () async {
      scope = _TestScope();
      final service = scope.build();
      addTearDown(service.dispose);

      await service.setActiveAddress("bc1qxyz");

      verify(() => scope.walletAddresses.address = "bc1qxyz").called(1);
    });
  });

  group("setHidden", () {
    test("adds to hiddenAddresses when hidden = true and saves", () async {
      final hidden = <String>{};
      scope = _TestScope(hiddenAddresses: hidden, walletType: WalletType.bitcoin);
      final service = scope.build();
      addTearDown(service.dispose);

      await service.setHidden("bc1qxyz", hidden: true);

      expect(hidden, contains("bc1qxyz"));
      verify(scope.walletAddresses.saveAddressesInBox).called(1);
    });

    test("removes from hiddenAddresses when hidden = false", () async {
      final hidden = <String>{"bc1qxyz", "bc1qother"};
      scope = _TestScope(hiddenAddresses: hidden, walletType: WalletType.bitcoin);
      final service = scope.build();
      addTearDown(service.dispose);

      await service.setHidden("bc1qxyz", hidden: false);

      expect(hidden, isNot(contains("bc1qxyz")));
      expect(hidden, contains("bc1qother"));
    });

    test("setHidden(true) is idempotent — Set keeps a single entry", () async {
      final hidden = <String>{};
      scope = _TestScope(hiddenAddresses: hidden, walletType: WalletType.bitcoin);
      final service = scope.build();
      addTearDown(service.dispose);

      await service.setHidden("bc1qxyz", hidden: true);
      await service.setHidden("bc1qxyz", hidden: true);

      expect(hidden, {"bc1qxyz"});
      verify(scope.walletAddresses.saveAddressesInBox).called(2);
    });

    test("setHidden(false) on a not-hidden address is a safe no-op on the set", () async {
      final hidden = <String>{};
      scope = _TestScope(hiddenAddresses: hidden, walletType: WalletType.bitcoin);
      final service = scope.build();
      addTearDown(service.dispose);

      await service.setHidden("bc1qxyz", hidden: false);

      expect(hidden, isEmpty);
    });
  });

  group("deleteSilentPaymentAddress", () {
    test("no-op for non-Bitcoin wallets", () async {
      scope = _TestScope(walletType: WalletType.litecoin);
      final service = scope.build();
      addTearDown(service.dispose);

      await service.deleteSilentPaymentAddress("addr");

      verifyNever(() => scope.walletAddresses.address = any());
    });
  });

  group("setAddressType", () {
    test("no-op for wallet types outside {bitcoin, litecoin, zcash}", () async {
      for (final t in const [
        WalletType.monero,
        WalletType.wownero,
        WalletType.solana,
        WalletType.tron,
        WalletType.decred,
        WalletType.nano,
      ]) {
        scope = _TestScope(walletType: t);
        final service = scope.build();

        await service.setAddressType(ReceivePageOption.mainnet);

        verifyNever(() => scope.walletInfo.save());
        await service.dispose();
        await scope.dispose();
      }
      scope = _TestScope();
    });
  });

  group("applyOpenDefaults", () {
    test("no-op for non-Bitcoin wallets, regardless of lightningMode", () async {
      for (final t in const [
        WalletType.litecoin,
        WalletType.monero,
        WalletType.solana,
        WalletType.zcash,
      ]) {
        scope = _TestScope(walletType: t);
        final service = scope.build();

        await service.applyOpenDefaults(lightningMode: true);
        await service.applyOpenDefaults(lightningMode: false);

        verifyNever(() => scope.walletInfo.save());
        await service.dispose();
        await scope.dispose();
      }
      scope = _TestScope();
    });
  });

  group("dismissInfobox", () {
    test("sets wallet.walletInfo.receiveInfoboxDismissed = true and saves", () async {
      scope = _TestScope(infoboxDismissed: false);
      final service = scope.build();
      addTearDown(service.dispose);

      await service.dismissInfobox();

      verify(() => scope.walletInfo.receiveInfoboxDismissed = true).called(1);
      verify(scope.walletInfo.save).called(1);
    });

    test("swallows save errors", () async {
      scope = _TestScope();
      when(scope.walletInfo.save).thenThrow(Exception("disk full"));
      final service = scope.build();
      addTearDown(service.dispose);

      // Should NOT throw.
      await service.dismissInfobox();

      verify(() => scope.walletInfo.receiveInfoboxDismissed = true).called(1);
    });
  });

  group("buildPaymentUri / fetchPaymentRequestUri (default path)", () {
    test(
      "buildPaymentUri without token delegates to wallet.walletAddresses.getPaymentUri",
      () {
        scope = _TestScope(walletType: WalletType.bitcoin);
        final uri = _FakePaymentURI("bitcoin:addr?amount=1");
        when(() => scope.walletAddresses.getPaymentUri("1")).thenReturn(uri);
        final service = scope.build();
        addTearDown(service.dispose);

        final result = service.buildPaymentUri(amount: Money.parse("1", CryptoCurrency.btc));

        expect(result, same(uri));
      },
    );

    test(
      "fetchPaymentRequestUri without an EVM token delegates to getPaymentRequestUri",
      () async {
        scope = _TestScope(walletType: WalletType.bitcoin);
        final uri = _FakePaymentURI("lightning:invoice");
        when(() => scope.walletAddresses.getPaymentRequestUri("100")).thenAnswer((_) async => uri);
        final service = scope.build();
        addTearDown(service.dispose);

        final result =
            await service.fetchPaymentRequestUri(amount: Money.parse("100", CryptoCurrency.btc));

        expect(result, same(uri));
      },
    );
  });

  group("useSatoshi", () {
    test("useSatoshi(btc) is false under bitcoin display mode", () {
      scope = _TestScope();
      final service = scope.build(mode: BitcoinAmountDisplayMode.bitcoin);
      addTearDown(service.dispose);

      expect(service.useSatoshi(CryptoCurrency.btc), isFalse);
    });

    test("useSatoshi(btc) is true under satoshi display mode", () {
      scope = _TestScope();
      final service = scope.build(mode: BitcoinAmountDisplayMode.satoshi);
      addTearDown(service.dispose);

      expect(service.useSatoshi(CryptoCurrency.btc), isTrue);
    });

    test("useSatoshi(btcln) is true under satoshiForLightning mode", () {
      scope = _TestScope();
      final service = scope.build(mode: BitcoinAmountDisplayMode.satoshiForLightning);
      addTearDown(service.dispose);

      expect(service.useSatoshi(CryptoCurrency.btcln), isTrue);
      // BTC does NOT get sats in satoshiForLightning mode.
      expect(service.useSatoshi(CryptoCurrency.btc), isFalse);
    });

    test("useSatoshi is always false for non-BTC currencies regardless of display mode", () {
      for (final mode in const [
        BitcoinAmountDisplayMode.bitcoin,
        BitcoinAmountDisplayMode.satoshi,
        BitcoinAmountDisplayMode.satoshiForLightning,
      ]) {
        scope = _TestScope();
        final service = scope.build(mode: mode);
        for (final c in const [
          CryptoCurrency.eth,
          CryptoCurrency.xmr,
          CryptoCurrency.sol,
          CryptoCurrency.trx,
        ]) {
          expect(service.useSatoshi(c), isFalse, reason: "$mode + $c");
        }
        service.dispose();
      }
      scope = _TestScope();
    });
  });

  group("payjoinEndpointChanges stream", () {
    test("is a broadcast stream", () {
      scope = _TestScope();
      final service = scope.build();
      addTearDown(service.dispose);

      expect(service.payjoinEndpointChanges.isBroadcast, isTrue);
    });

    test("emits null on rebind for non-Bitcoin wallets", () async {
      scope = _TestScope(walletType: WalletType.monero);
      final service = scope.build();
      addTearDown(service.dispose);
      final events = <String?>[];
      final sub = service.payjoinEndpointChanges.listen(events.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);
      events.clear();

      scope._walletChanges.add(scope.wallet);
      await Future<void>.delayed(Duration.zero);

      expect(events, [null]);
    });
  });

  group("dispose", () {
    test("closes the payjoinEndpointChanges stream and cancels the wallet subscription", () async {
      scope = _TestScope(walletType: WalletType.monero);
      final service = scope.build();
      final events = <String?>[];
      final done = Completer<void>();
      final sub = service.payjoinEndpointChanges.listen(
        events.add,
        onDone: done.complete,
      );
      addTearDown(sub.cancel);

      await service.dispose();
      await done.future;

      // Emitting a wallet change after dispose must not trigger anything.
      scope._walletChanges.add(scope.wallet);
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
    });

    test("constructor survives a wallet getter that throws (post-logout scenario)", () {
      scope = _TestScope();
      final failingScope = _FailingScope();
      addTearDown(failingScope.dispose);

      final service = failingScope.build();
      addTearDown(service.dispose);

      failingScope.emit();
    });
  });
}

class _FailingScope {
  final _walletChanges = StreamController<WalletBase>.broadcast();
  final _settings = _FakeSettingsStore();

  AddressService build() => AddressService(
        wallet: () => throw StateError("No wallet is active yet"),
        walletChanges: _walletChanges.stream,
        settingsStore: _settings,
        amountParsingProxyGetter: () => const AmountParsingProxy(BitcoinAmountDisplayMode.bitcoin),
      );

  void emit() {
    _walletChanges.add(_MockWallet());
  }

  Future<void> dispose() async {
    await _walletChanges.close();
  }
}
