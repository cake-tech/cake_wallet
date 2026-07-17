import "dart:async";

import "package:bloc_test/bloc_test.dart";
import "package:cake_wallet/core/active_wallet_service.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/core/fiat_rate_service.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/viewmodels/receive/receive_bloc.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
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

const _btcAddress = AddressEntry(address: "bc1qtestaddress", isPrimary: true);
final _btcUri = BitcoinURI(address: _btcAddress.address, amount: "");

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeReceivePageOption());
    registerFallbackValue(_FakeCryptoCurrency());
    registerFallbackValue(_FakeFiatCurrency());
    registerFallbackValue(_FakeMoney());
  });

  late _MockAddressService addressService;
  late _MockFiatRateService fiatRateService;
  late _MockActiveWalletService activeWalletService;
  late StreamController<WalletBase> walletChangesController;
  late StreamController<void> rateChangesController;
  late StreamController<String?> payjoinController;

  ReceiveBloc buildBloc({ReceivePageOption? typeOverride, CryptoCurrency? initialToken}) =>
      ReceiveBloc(
        addressService: addressService,
        fiatRateService: fiatRateService,
        activeWalletService: activeWalletService,
        typeOverride: typeOverride,
        initialToken: initialToken,
      );

  void wireDefaults({
    WalletType walletType = WalletType.bitcoin,
    CryptoCurrency? walletCurrency,
    List<CryptoCurrency> receivableTokens = const [],
    bool infoboxDismissed = false,
    bool hasAccounts = false,
    List<ReceivePageOption> options = const [],
    List<AddressGroup> addressGroups = const [],
    String currentAddress = "bc1qtestaddress",
    String payjoinEndpoint = "",
    bool isSilentPayments = false,
    bool isBitcoinViewOnly = false,
    bool isAutoGenerateSubaddressEnabled = false,
    bool isZCashTransparent = true,
    AddressAccount? currentAccount,
    ReceivePageOption? selectedAddressType,
    PaymentURI? initialUri,
  }) {
    when(() => addressService.walletType).thenReturn(walletType);
    when(() => addressService.walletCurrency).thenReturn(walletCurrency ?? CryptoCurrency.btc);
    when(() => addressService.walletChainId).thenReturn(null);
    when(() => addressService.receivableTokens).thenReturn(receivableTokens);
    when(() => addressService.infoboxDismissed).thenReturn(infoboxDismissed);
    when(() => addressService.hasAccounts).thenReturn(hasAccounts);
    when(() => addressService.addressTypeOptions).thenReturn(options);
    when(() => addressService.computeAddressList()).thenReturn(addressGroups);
    when(() => addressService.currentAddress).thenReturn(currentAddress);
    when(() => addressService.payjoinEndpoint).thenReturn(payjoinEndpoint);
    when(() => addressService.isSilentPayments).thenReturn(isSilentPayments);
    when(() => addressService.isBitcoinViewOnly).thenReturn(isBitcoinViewOnly);
    when(
      () => addressService.isAutoGenerateSubaddressEnabled,
    ).thenReturn(isAutoGenerateSubaddressEnabled);
    when(() => addressService.isZCashTransparent).thenReturn(isZCashTransparent);
    when(() => addressService.currentAccount).thenReturn(currentAccount);
    when(() => addressService.selectedAddressType).thenReturn(selectedAddressType);
    when(
      () => addressService.buildPaymentUri(
        rawAmount: any(named: "rawAmount"),
        token: any(named: "token"),
      ),
    ).thenReturn(initialUri ?? _btcUri);
    when(() => addressService.payjoinEndpointChanges).thenAnswer((_) => payjoinController.stream);

    when(() => fiatRateService.defaultFiat).thenReturn(FiatCurrency.usd);
    when(() => fiatRateService.rateChanges).thenAnswer((_) => rateChangesController.stream);
    when(() => fiatRateService.ensureRateFor(any(), any())).thenAnswer((_) async {});

    when(() => activeWalletService.walletChanges).thenAnswer((_) => walletChangesController.stream);
  }

  setUp(() {
    addressService = _MockAddressService();
    fiatRateService = _MockFiatRateService();
    activeWalletService = _MockActiveWalletService();
    walletChangesController = StreamController<WalletBase>.broadcast();
    rateChangesController = StreamController<void>.broadcast();
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
      build: buildBloc,
      expect: () => [isA<ReceiveLoading>(), isA<ReceiveLoaded>()],
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "applies typeOverride via setAddressType",
      setUp: () {
        wireDefaults();
        when(() => addressService.setAddressType(any())).thenAnswer((_) async {});
      },
      build: () => buildBloc(typeOverride: ReceivePageOption.mainnet),
      verify: (_) {
        verify(() => addressService.setAddressType(ReceivePageOption.mainnet)).called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "does not call setAddressType for anonpay options",
      setUp: () {
        wireDefaults();
        when(() => addressService.setAddressType(any())).thenAnswer((_) async {});
      },
      build: () => buildBloc(typeOverride: ReceivePageOption.anonPayInvoice),
      verify: (_) {
        verifyNever(() => addressService.setAddressType(any()));
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "carries tokenCurrency when initialToken differs from wallet currency",
      setUp: () {
        wireDefaults(walletCurrency: CryptoCurrency.eth);
      },
      build: () => buildBloc(initialToken: CryptoCurrency.usdc),
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
      build: () => buildBloc(initialToken: CryptoCurrency.btc),
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
      build: buildBloc,
      expect: () => [isA<ReceiveLoading>(), isA<ReceiveFailure>()],
    );
  });

  group("amount changes", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "parses crypto amount and computes fiat equivalent",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convertToFiat(any(), any())).thenReturn(
          Money.parse("50000.00", FiatCurrency.usd),
        );
      },
      build: buildBloc,
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
      build: buildBloc,
      act: (bloc) => bloc.add(const AmountChanged("")),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.requestedAmount, isNull);
        expect(state.fiatEquivalent, isNull);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "rapid changes end in the state for the last input (restartable)",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convertToFiat(any(), any())).thenReturn(
          Money.parse("0.00", FiatCurrency.usd),
        );
      },
      build: buildBloc,
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
        when(() => fiatRateService.convertFromFiat(any(), any())).thenReturn(
          Money.parse("0.5", CryptoCurrency.btc),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const InputCurrencySelected(FiatCurrency.usd));
        await Future.delayed(const Duration(milliseconds: 30));
        bloc.add(const AmountChanged("100"));
        await Future.delayed(const Duration(milliseconds: 30));
      },
      verify: (_) {
        verify(() => fiatRateService.convertFromFiat(any(), CryptoCurrency.btc))
            .called(greaterThan(0));
      },
    );
  });

  group("token preset", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "sets tokenCurrency and rebuilds URI",
      setUp: () {
        wireDefaults(walletCurrency: CryptoCurrency.eth);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const TokenPresetSelected(CryptoCurrency.usdc)),
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
      build: () => buildBloc(initialToken: CryptoCurrency.usdc),
      act: (bloc) => bloc.add(const TokenPresetSelected(CryptoCurrency.eth)),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.tokenCurrency, isNull);
      },
    );
  });

  group("address type", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "delegates to service.setAddressType and refreshes state",
      setUp: () {
        wireDefaults();
        when(() => addressService.setAddressType(any())).thenAnswer((_) async {});
      },
      build: buildBloc,
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
      build: buildBloc,
      act: (bloc) => bloc.add(const AddressTypeSelected(ReceivePageOption.anonPayInvoice)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        verifyNever(() => addressService.setAddressType(ReceivePageOption.anonPayInvoice));
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
      build: buildBloc,
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
      build: buildBloc,
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
  });

  group("label", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "delegates to service.setLabel and refreshes address entry",
      setUp: () {
        wireDefaults();
        when(() => addressService.setLabel(any(), any())).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LabelSubmitted("Donations")),
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(() => addressService.setLabel(any(), "Donations")).called(1);
      },
    );
  });

  group("infobox", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "marks infoboxDismissed once",
      setUp: () {
        wireDefaults();
        when(() => addressService.dismissInfobox()).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const InfoboxDismissed()),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.infoboxDismissed, isTrue);
        verify(() => addressService.dismissInfobox()).called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "no-op when already dismissed",
      setUp: () {
        wireDefaults(infoboxDismissed: true);
        when(() => addressService.dismissInfobox()).thenAnswer((_) async {});
      },
      build: buildBloc,
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
      build: buildBloc,
      act: (bloc) => bloc.add(const AddressesPageClosed()),
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        // Rebuilds URI on refresh
        verify(
          () => addressService.buildPaymentUri(
            rawAmount: any(named: "rawAmount"),
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
      build: buildBloc,
      act: (_) async {
        await Future.delayed(const Duration(milliseconds: 20));
        walletChangesController.add(_FakeWallet());
        await Future.delayed(const Duration(milliseconds: 20));
      },
      skip: 2, // initial Loading + Loaded
      expect: () => [isA<ReceiveLoading>(), isA<ReceiveLoaded>()],
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "fiat rate change refreshes fiatEquivalent when amount is set",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convertToFiat(any(), any())).thenReturn(
          Money.parse("50000.00", FiatCurrency.usd),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const AmountChanged("1.0"));
        await Future.delayed(const Duration(milliseconds: 20));
        rateChangesController.add(null);
        await Future.delayed(const Duration(milliseconds: 20));
      },
      verify: (_) {
        verify(() => fiatRateService.convertToFiat(any(), any())).called(greaterThan(1));
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "payjoin endpoint stream updates state.payjoinEndpoint",
      setUp: () {
        wireDefaults();
        when(() => addressService.payjoinEndpoint).thenReturn("https://payjo.in/abc");
      },
      build: buildBloc,
      act: (_) async {
        await Future.delayed(const Duration(milliseconds: 20));
        payjoinController.add("https://payjo.in/abc");
        await Future.delayed(const Duration(milliseconds: 20));
      },
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.payjoinEndpoint, "https://payjo.in/abc");
      },
    );
  });
}

class _FakeWallet extends Fake implements WalletBase {}
