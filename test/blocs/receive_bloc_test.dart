import "dart:async";

import "package:bloc_test/bloc_test.dart";
import "package:cake_wallet/core/active_wallet_service.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/core/fiat_rate_service.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/viewmodels/receive/receive_bloc.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockAddressService extends Mock implements AddressService {}

class _MockFiatRateService extends Mock implements FiatRateService {}

class _MockActiveWalletService extends Mock implements ActiveWalletService {}

class _FakeReceivePageOption extends Fake implements ReceivePageOption {}

class _FakeCryptoCurrency extends Fake implements CryptoCurrency {}

class _FakeFiatCurrency extends Fake implements FiatCurrency {}

class _FakeMoney extends Fake implements Money {}

class _FakeCurrency extends Fake implements Currency {}

class _FakeWalletBase extends Fake implements WalletBase {}

const _btcAddress = AddressEntry(address: "bc1qtestaddress");
final _btcUri = BitcoinURI(address: _btcAddress.address, amount: "");

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeReceivePageOption());
    registerFallbackValue(_FakeCryptoCurrency());
    registerFallbackValue(_FakeFiatCurrency());
    registerFallbackValue(_FakeMoney());
    registerFallbackValue(_FakeCurrency());
  });

  late _MockAddressService addressService;
  late _MockFiatRateService fiatRateService;
  late _MockActiveWalletService activeWalletService;
  late StreamController<WalletBase> walletChangesController;
  late StreamController<FiatCurrency> rateChangesController;
  late StreamController<String?> payjoinController;

  void wireDefaults({
    WalletType walletType = WalletType.bitcoin,
    CryptoCurrency? walletCurrency,
    List<CryptoCurrency> receivableTokens = const [],
    bool isInfoboxDismissed = false,
    bool hasAccounts = false,
    List<ReceivePageOption> options = const [],
    List<AddressGroup> addressGroups = const [],
    String currentAddress = "bc1qtestaddress",
    bool isSilentPayments = false,
    bool isAutoGenerateSubaddressEnabled = false,
    bool isZCashTransparent = true,
    ReceivePageOption? selectedAddressType,
    PaymentURI? initialUri,
  }) {
    when(() => addressService.walletType).thenReturn(walletType);
    when(() => addressService.walletId).thenReturn("wallet-a");
    when(() => addressService.walletName).thenReturn("wallet-a");
    when(() => addressService.walletCurrency).thenReturn(walletCurrency ?? CryptoCurrency.btc);
    when(() => addressService.receivableTokens).thenReturn(receivableTokens);
    when(() => addressService.isInfoboxDismissed).thenReturn(isInfoboxDismissed);
    when(() => addressService.hasAccounts).thenReturn(hasAccounts);
    when(() => addressService.addressTypeOptions).thenReturn(options);
    when(() => addressService.computeAddressList()).thenReturn(addressGroups);
    when(() => addressService.currentAddress).thenReturn(currentAddress);
    when(() => addressService.isSilentPayments).thenReturn(isSilentPayments);
    when(
      () => addressService.isAutoGenerateSubaddressEnabled,
    ).thenReturn(isAutoGenerateSubaddressEnabled);
    when(() => addressService.isZCashTransparent).thenReturn(isZCashTransparent);
    when(() => addressService.useSatoshi(any())).thenReturn(false);
    when(() => addressService.canonicalCryptoAmount(any(), any()))
        .thenAnswer((invocation) => invocation.positionalArguments[0] as String);
    when(() => addressService.autoGenerateSubaddressStatus)
        .thenReturn(AutoGenerateSubaddressStatus.disabled);
    when(() => addressService.hasTokens).thenReturn(false);
    when(() => addressService.applyOpenDefaults(lightningMode: any(named: "lightningMode")))
        .thenAnswer((_) async {});
    when(() => addressService.selectedAddressType).thenReturn(selectedAddressType);
    when(
      () => addressService.buildPaymentUri(
        amount: any(named: "amount"),
        token: any(named: "token"),
      ),
    ).thenReturn(initialUri ?? _btcUri);
    when(() => addressService.payjoinEndpointChanges).thenAnswer((_) => payjoinController.stream);

    when(() => fiatRateService.currentFiat).thenReturn(FiatCurrency.usd);
    when(() => fiatRateService.rateChanges).thenAnswer((_) => rateChangesController.stream);
    when(() => fiatRateService.ensureRateFor(any(), any())).thenAnswer((_) async {});

    when(() => activeWalletService.walletChanges).thenAnswer((_) => walletChangesController.stream);
  }

  setUp(() {
    addressService = _MockAddressService();
    fiatRateService = _MockFiatRateService();
    activeWalletService = _MockActiveWalletService();
    walletChangesController = StreamController<WalletBase>.broadcast();
    rateChangesController = StreamController<FiatCurrency>.broadcast();
    payjoinController = StreamController<String?>.broadcast();
  });

  tearDown(() async {
    await walletChangesController.close();
    await rateChangesController.close();
    await payjoinController.close();
  });

  group("initialization", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "emits Loading then Loaded on init",
      setUp: wireDefaults,
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      expect: () => [isA<ReceiveLoading>(), isA<ReceiveLoaded>()],
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "applies lightning open defaults when opened with the lightning token",
      setUp: wireDefaults,
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
        initialToken: CryptoCurrency.btcln,
      ),
      verify: (bloc) {
        verify(() => addressService.applyOpenDefaults(lightningMode: true)).called(1);
        final state = bloc.state as ReceiveLoaded;
        expect(state.tokenCurrency, CryptoCurrency.btcln);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "applies non-lightning open defaults without the lightning token",
      setUp: wireDefaults,
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      verify: (_) {
        verify(() => addressService.applyOpenDefaults(lightningMode: false)).called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "carries tokenCurrency when initialToken differs from wallet currency",
      setUp: () {
        wireDefaults(walletCurrency: CryptoCurrency.eth);
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
        initialToken: CryptoCurrency.usdc,
      ),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.tokenCurrency, CryptoCurrency.usdc);
        expect(state.inputCurrency, CryptoCurrency.usdc);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "null tokenCurrency when initialToken equals wallet currency",
      setUp: () {
        wireDefaults(walletCurrency: CryptoCurrency.btc);
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
        initialToken: CryptoCurrency.btc,
      ),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.tokenCurrency, isNull);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "emits Failure when address service throws during init",
      setUp: () {
        wireDefaults();
        when(() => addressService.computeAddressList()).thenThrow(Exception("boom"));
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      expect: () => [isA<ReceiveLoading>(), isA<ReceiveFailure>()],
    );
  });

  group("amount changes", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "parses crypto amount and computes fiat equivalent",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convert(any(), any())).thenReturn(
          Money.parse("50000.00", FiatCurrency.usd),
        );
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const AmountChanged("1.0")),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.requestedAmount, isNotNull);
        expect(state.fiatEquivalent, isNotNull);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "clears amounts on empty input",
      setUp: wireDefaults,
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const AmountChanged("")),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.requestedAmount, isNull);
        expect(state.fiatEquivalent, isNull);
      },
    );

    // Regression: satoshiForLightning display mode + lightning token used to
    // multiply the amount by 10^8 per modal round-trip because the BTCLN→BTC
    // substitution in _receiveCryptoCurrency was applied before the sats
    // check (useSatoshi(BTC) is false in that mode, but useSatoshi(BTCLN) is
    // true). See bug where "1235" showed as "123500000000 sats".
    blocTest<ReceiveBloc, ReceiveState>(
      "lightning token in satoshi-for-lightning mode treats input as sats",
      setUp: () {
        wireDefaults();
        when(() => addressService.useSatoshi(CryptoCurrency.btcln)).thenReturn(true);
        when(() => addressService.useSatoshi(CryptoCurrency.btc)).thenReturn(false);
        when(() => addressService.canonicalCryptoAmount("1235", CryptoCurrency.btcln))
            .thenReturn("0.00001235");
        when(() => addressService.canonicalCryptoAmount("1235", CryptoCurrency.btc))
            .thenReturn("1235");
        when(
          () => addressService.fetchPaymentRequestUri(
            amount: any(named: "amount"),
            token: any(named: "token"),
          ),
        ).thenAnswer((_) async => _btcUri);
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
        initialToken: CryptoCurrency.btcln,
      ),
      act: (bloc) => bloc.add(const AmountChanged("1235")),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        // 1235 sats = 1235 in the base-unit BigInt (BTC decimals=8, stored as sats).
        expect(state.requestedAmount?.amount.toString(), "1235");
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "rapid changes end in the state for the last input (restartable)",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convert(any(), any())).thenReturn(
          Money.parse("0.00", FiatCurrency.usd),
        );
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) {
        bloc
          ..add(const AmountChanged("1.0"))
          ..add(const AmountChanged("2.0"))
          ..add(const AmountChanged("3.0"));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        // 3.0 BTC in sats = 300_000_000
        expect(state.requestedAmount?.amount.toString(), "300000000");
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "in fiat input mode, converts fiat to crypto via FiatRateService",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convert(any(), any())).thenReturn(
          Money.parse("0.5", CryptoCurrency.btc),
        );
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) async {
        bloc.add(const InputCurrencySelected(FiatCurrency.usd));
        await Future.delayed(const Duration(milliseconds: 30));
        bloc.add(const AmountChanged("100"));
        await Future.delayed(const Duration(milliseconds: 30));
      },
      verify: (_) {
        verify(() => fiatRateService.convert(any(), CryptoCurrency.btc)).called(greaterThan(0));
      },
    );
  });

  group("token preset", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "sets tokenCurrency and rebuilds URI",
      setUp: () {
        wireDefaults(
          walletCurrency: CryptoCurrency.eth,
          receivableTokens: const [CryptoCurrency.usdc],
        );
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const TokenSelected(CryptoCurrency.usdc)),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.tokenCurrency, CryptoCurrency.usdc);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "clears tokenCurrency when preset matches walletCurrency",
      setUp: () {
        wireDefaults(walletCurrency: CryptoCurrency.eth);
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
        initialToken: CryptoCurrency.usdc,
      ),
      act: (bloc) => bloc.add(const TokenSelected(CryptoCurrency.eth)),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.tokenCurrency, isNull);
      },
    );
  });

  group("address type", () {
    late Completer<void> setTypeCompleter;

    blocTest<ReceiveBloc, ReceiveState>(
      "delegates to service.setAddressType and refreshes state",
      setUp: () {
        wireDefaults();
        when(() => addressService.setAddressType(any())).thenAnswer((_) async {});
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const AddressTypeSelected(ReceivePageOption.mainnet)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        verify(() => addressService.setAddressType(ReceivePageOption.mainnet)).called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "ignores anonpay options defensively",
      setUp: () {
        wireDefaults();
        when(() => addressService.setAddressType(any())).thenAnswer((_) async {});
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const AddressTypeSelected(ReceivePageOption.anonPayInvoice)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        verifyNever(() => addressService.setAddressType(ReceivePageOption.anonPayInvoice));
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "setAddressType failure keeps the bloc in Loaded",
      setUp: () {
        wireDefaults();
        when(() => addressService.setAddressType(any())).thenThrow(Exception("boom"));
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const AddressTypeSelected(ReceivePageOption.mainnet)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state, isA<ReceiveLoaded>());
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "wallet change during setAddressType suppresses the stale emit",
      setUp: () {
        wireDefaults();
        setTypeCompleter = Completer<void>();
        when(() => addressService.setAddressType(any())).thenAnswer((_) => setTypeCompleter.future);
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const AddressTypeSelected(ReceivePageOption.mainnet));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        when(() => addressService.walletType).thenReturn(WalletType.monero);
        when(() => addressService.walletId).thenReturn("wallet-b");
        walletChangesController.add(_FakeWalletBase());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        setTypeCompleter.complete();
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.walletType, WalletType.monero);
        expect(state.addressType, isNull);
      },
    );
  });

  group("rotation", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "sets isRotatingAddress true while rotating, false after",
      setUp: () {
        wireDefaults();
        when(() => addressService.rotateAddress()).thenAnswer((_) async {});
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const AddressRotated()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.isRotatingAddress, isFalse);
        verify(() => addressService.rotateAddress()).called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "droppable: back-to-back rotate events run once",
      setUp: () {
        wireDefaults();
        final completer = Completer<void>();
        when(() => addressService.rotateAddress()).thenAnswer((_) => completer.future);
        Future.delayed(const Duration(milliseconds: 20), completer.complete);
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) {
        bloc
          ..add(const AddressRotated())
          ..add(const AddressRotated());
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        verify(() => addressService.rotateAddress()).called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "rotation failure still clears isRotatingAddress",
      setUp: () {
        wireDefaults();
        when(() => addressService.rotateAddress()).thenThrow(Exception("boom"));
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const AddressRotated()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.isRotatingAddress, isFalse);
      },
    );
  });

  group("label", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "delegates to service.setLabel and refreshes address entry",
      setUp: () {
        wireDefaults();
        when(() => addressService.setLabel(any(), any())).thenAnswer((_) async {});
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const LabelSubmitted("Donations")),
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(() => addressService.setLabel(any(), "Donations")).called(1);
      },
    );
  });

  group("infobox", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "marks the infobox dismissed once",
      setUp: () {
        wireDefaults();
        when(() => addressService.dismissInfobox()).thenAnswer((_) async {});
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const InfoboxDismissed()),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.isInfoboxDismissed, isTrue);
        verify(() => addressService.dismissInfobox()).called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "no-op when already dismissed",
      setUp: () {
        wireDefaults(isInfoboxDismissed: true);
        when(() => addressService.dismissInfobox()).thenAnswer((_) async {});
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const InfoboxDismissed()),
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verifyNever(() => addressService.dismissInfobox());
      },
    );
  });

  group("addresses page closed", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "refreshes address entry and payment URI",
      setUp: wireDefaults,
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) => bloc.add(const AddressesPageClosed()),
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        // Rebuilds URI on refresh
        verify(
          () => addressService.buildPaymentUri(
            amount: any(named: "amount"),
            token: any(named: "token"),
          ),
        ).called(greaterThan(1));
      },
    );
  });

  group("streams", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "wallet change triggers re-init (Loading emit)",
      setUp: wireDefaults,
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (_) async {
        await Future.delayed(const Duration(milliseconds: 20));
        walletChangesController.add(_FakeWalletBase());
        await Future.delayed(const Duration(milliseconds: 20));
      },
      skip: 2, // initial Loading + Loaded
      expect: () => [isA<ReceiveLoading>(), isA<ReceiveLoaded>()],
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "fiat rate change refreshes fiatEquivalent when amount is set",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convert(any(), any())).thenReturn(
          Money.parse("50000.00", FiatCurrency.usd),
        );
      },
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (bloc) async {
        bloc.add(const AmountChanged("1.0"));
        await Future.delayed(const Duration(milliseconds: 20));
        rateChangesController.add(FiatCurrency.usd);
        await Future.delayed(const Duration(milliseconds: 20));
      },
      verify: (_) {
        verify(() => fiatRateService.convert(any(), any())).called(greaterThan(1));
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "payjoin endpoint stream rebuilds the payment URI",
      setUp: wireDefaults,
      build: () => ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
      ),
      act: (_) async {
        await Future.delayed(const Duration(milliseconds: 20));
        when(
          () => addressService.buildPaymentUri(
            amount: any(named: "amount"),
            token: any(named: "token"),
          ),
        ).thenReturn(
          BitcoinURI(
            address: _btcAddress.address,
            amount: "",
            pjUri: "https://payjo.in/abc",
          ),
        );
        payjoinController.add("https://payjo.in/abc");
        await Future.delayed(const Duration(milliseconds: 20));
      },
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.paymentUri.toString(), contains("pj="));
        expect(state.hasPayjoin, isTrue);
      },
    );
  });
}
