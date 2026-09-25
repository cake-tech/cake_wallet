import "dart:async";

import "package:bloc_test/bloc_test.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/fiat_rate_service.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/viewmodels/receive/receive_bloc.dart";
import "package:cw_core/address_entry.dart";
import "package:cw_core/address_generation_wallet.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" as mobx;
import "package:mocktail/mocktail.dart";

class _MockAddressService extends Mock implements AddressService {}

class _MockFiatRateService extends Mock implements FiatRateService {}

class _FakeCryptoCurrency extends Fake implements CryptoCurrency {}

class _FakeFiatCurrency extends Fake implements FiatCurrency {}

class _FakeMoney extends Fake implements Money {}

class _FakeCurrency extends Fake implements Currency {}

class _MockWallet extends Mock implements WalletBase {}

class _MockGeneratingWallet extends Mock implements WalletBase, AddressGenerationWallet {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _MockWalletInfo extends Mock implements WalletInfo {}

class _Option implements ReceivePageOption {
  const _Option(this.value, {this.canRotateAddress = true});

  @override
  final String value;
  @override
  String? get iconPath => null;
  @override
  String? get description => null;
  @override
  bool get isCommon => false;
  @override
  bool get addAddressWord => false;
  @override
  final bool canRotateAddress;
}

const _defaultType = _Option("default-type");
const _otherType = _Option("other-type");
const _staticType = _Option("static-type", canRotateAddress: false);

const _btcAddress = AddressEntry(address: "bc1qtestaddress", label: "Savings");
final _btcUri = BitcoinURI(address: _btcAddress.address, amount: "");
final _lightningUri =
    LightningPaymentRequest(address: "user@cake.cash", amount: "", lnURL: "lnurl1");

void main() {
  setUpAll(() {
    registerFallbackValue(_defaultType);
    registerFallbackValue(_FakeCryptoCurrency());
    registerFallbackValue(_FakeFiatCurrency());
    registerFallbackValue(_FakeMoney());
    registerFallbackValue(_FakeCurrency());
    registerFallbackValue(_btcAddress);
    registerFallbackValue(_MockWallet());
  });

  late _MockAddressService addressService;
  late _MockFiatRateService fiatRateService;
  late StreamController<FiatCurrency> rateChangesController;
  late StreamController<void> payjoinController;
  late WalletBase wallet;
  late _MockWalletAddresses walletAddresses;
  late _MockWalletInfo walletInfo;

  ReceiveBloc buildBloc({CryptoCurrency? initialToken, ReceivePageOption? initialAddressType}) =>
      ReceiveBloc(
        wallet: wallet,
        addressService: addressService,
        fiatRateService: fiatRateService,
        initialToken: initialToken,
        initialAddressType: initialAddressType,
      );

  void stubPaymentUri(PaymentURI uri) => when(
        () => walletAddresses.paymentUriFor(any(), any(), token: any(named: "token")),
      ).thenReturn(uri);

  void wireDefaults({
    WalletType walletType = WalletType.bitcoin,
    CryptoCurrency? walletCurrency,
    List<CryptoCurrency> receivableTokens = const [],
    bool isInfoboxDismissed = false,
    List<ReceivePageOption> options = const [_defaultType, _otherType, _staticType],
    List<AddressGroup> addressGroups = const [],
    String currentAddress = "bc1qtestaddress",
    bool canGenerate = false,
    PaymentURI? initialUri,
    bool isAutoGenerateSubaddress = false,
    String latestAddress = "",
  }) {
    walletInfo = _MockWalletInfo();
    when(() => walletInfo.receiveInfoboxDismissed).thenReturn(isInfoboxDismissed);
    when(walletInfo.save).thenAnswer((_) async => 0);

    walletAddresses = _MockWalletAddresses();
    when(() => walletAddresses.defaultAddressType).thenReturn(_defaultType);
    when(() => walletAddresses.addressListFor(any())).thenReturn(addressGroups);
    when(() => walletAddresses.addressFor(any())).thenReturn(currentAddress);
    when(() => walletAddresses.latestAddress).thenReturn(latestAddress);

    final WalletBase mockWallet = canGenerate ? _MockGeneratingWallet() : _MockWallet();
    when(() => mockWallet.type).thenReturn(walletType);
    when(() => mockWallet.currency).thenReturn(walletCurrency ?? CryptoCurrency.btc);
    when(() => mockWallet.walletInfo).thenReturn(walletInfo);
    when(() => mockWallet.walletAddresses).thenReturn(walletAddresses);
    when(() => mockWallet.addressTypeOptions).thenReturn(options);
    when(() => mockWallet.isEnabledAutoGenerateSubaddress).thenReturn(isAutoGenerateSubaddress);
    when(() => mockWallet.balance).thenReturn(
      mobx.ObservableMap<CryptoCurrency, Balance>.of({
        for (final token in receivableTokens) token: _FakeBalance(),
      }),
    );
    wallet = mockWallet;

    when(() => addressService.autoGenerateSubaddressStatus)
        .thenReturn(AutoGenerateSubaddressStatus.disabled);
    stubPaymentUri(initialUri ?? _btcUri);
    when(() => addressService.payjoinEndpointChanges(any()))
        .thenAnswer((_) => payjoinController.stream);

    when(() => fiatRateService.currentFiat).thenReturn(FiatCurrency.usd);
    when(() => fiatRateService.rateChanges).thenAnswer((_) => rateChangesController.stream);
    when(() => fiatRateService.ensureRateFor(any(), any())).thenAnswer((_) async {});
  }

  setUp(() {
    addressService = _MockAddressService();
    fiatRateService = _MockFiatRateService();
    rateChangesController = StreamController<FiatCurrency>.broadcast();
    payjoinController = StreamController<void>.broadcast();
  });

  tearDown(() async {
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
      "moves the wallet to its latest address on open when auto-generate is on",
      setUp: () => wireDefaults(isAutoGenerateSubaddress: true, latestAddress: "bc1qlatest"),
      build: buildBloc,
      verify: (_) {
        verify(() => walletAddresses.address = "bc1qlatest").called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "leaves the wallet address alone on open when auto-generate is off",
      setUp: () => wireDefaults(latestAddress: "bc1qlatest"),
      build: buildBloc,
      verify: (_) {
        verifyNever(() => walletAddresses.address = any());
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "leaves the wallet address alone on open when there is no latest address",
      setUp: () => wireDefaults(isAutoGenerateSubaddress: true),
      build: buildBloc,
      verify: (_) {
        verifyNever(() => walletAddresses.address = any());
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "opens on the wallet's default type when none is requested",
      setUp: wireDefaults,
      build: buildBloc,
      verify: (bloc) {
        expect((bloc.state as ReceiveLoaded).addressType, _defaultType);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "opens on the requested type when the wallet offers it",
      setUp: wireDefaults,
      build: () => buildBloc(initialAddressType: _otherType),
      verify: (bloc) {
        expect((bloc.state as ReceiveLoaded).addressType, _otherType);
        verify(() => walletAddresses.addressFor(_otherType)).called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "falls back to the default type when the requested one is not offered",
      setUp: () => wireDefaults(options: const [_defaultType]),
      build: () => buildBloc(initialAddressType: _otherType),
      verify: (bloc) {
        expect((bloc.state as ReceiveLoaded).addressType, _defaultType);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "opening on a Lightning type receives in BTCLN",
      setUp: () => wireDefaults(initialUri: _lightningUri),
      build: () => buildBloc(initialAddressType: _otherType),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.cryptoCurrency, CryptoCurrency.btcln);
        expect(state.isLightning, isTrue);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "a BTCLN token without a Lightning URI falls back to the wallet currency",
      setUp: wireDefaults,
      build: () => buildBloc(initialToken: CryptoCurrency.btcln),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.cryptoCurrency, CryptoCurrency.btc);
        expect(state.isLightning, isFalse);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "carries tokenCurrency when initialToken differs from wallet currency",
      setUp: () => wireDefaults(walletCurrency: CryptoCurrency.eth),
      build: () => buildBloc(initialToken: CryptoCurrency.usdc),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(bloc.selectedToken(state), CryptoCurrency.usdc);
        expect(state.inputCurrency, CryptoCurrency.usdc);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "null tokenCurrency when initialToken equals wallet currency",
      setUp: () => wireDefaults(walletCurrency: CryptoCurrency.btc),
      build: () => buildBloc(initialToken: CryptoCurrency.btc),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(bloc.selectedToken(state), isNull);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "emits Failure when the wallet address list throws during init",
      setUp: () {
        wireDefaults();
        when(() => walletAddresses.addressListFor(any())).thenThrow(Exception("boom"));
      },
      build: buildBloc,
      expect: () => [isA<ReceiveLoading>(), isA<ReceiveFailure>()],
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "picks the list entry of the current address, label included",
      setUp: () => wireDefaults(
        addressGroups: const [
          AddressGroup(entries: [AddressEntry(address: "bc1qother"), _btcAddress]),
        ],
      ),
      build: buildBloc,
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.addressEntry.address, "bc1qtestaddress");
        expect(state.addressEntry.label, "Savings");
      },
    );
  });

  group("address list and rotation flags", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "an empty list hides the list and rotation",
      setUp: () => wireDefaults(canGenerate: true),
      build: buildBloc,
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.hasAddressList, isFalse);
        expect(state.hasAddressRotation, isFalse);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "a list on a wallet that can't generate shows the list without rotation",
      setUp: () => wireDefaults(
        addressGroups: const [
          AddressGroup(entries: [_btcAddress]),
        ],
      ),
      build: buildBloc,
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(bloc.canGenerateAddresses, isFalse);
        expect(state.hasAddressList, isTrue);
        expect(state.hasAddressRotation, isFalse);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "a list on a generating wallet shows rotation for a rotating type",
      setUp: () => wireDefaults(
        canGenerate: true,
        addressGroups: const [
          AddressGroup(entries: [_btcAddress]),
        ],
      ),
      build: buildBloc,
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.hasAddressList, isTrue);
        expect(state.hasAddressRotation, isTrue);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "a type that can't rotate hides rotation",
      setUp: () => wireDefaults(
        canGenerate: true,
        addressGroups: const [
          AddressGroup(entries: [_btcAddress]),
        ],
      ),
      build: () => buildBloc(initialAddressType: _staticType),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.hasAddressList, isTrue);
        expect(state.hasAddressRotation, isFalse);
      },
    );
  });

  group("amount changes", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "sets crypto amount and computes fiat equivalent",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convert(any(), any())).thenReturn(
          Money.parse("50000.00", FiatCurrency.usd),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AmountChanged(Money.parse("1.0", CryptoCurrency.btc))),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.requestedAmount, isNotNull);
        expect(state.fiatEquivalent, isNotNull);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "clears amounts when amount is null",
      setUp: wireDefaults,
      build: buildBloc,
      act: (bloc) => bloc.add(const AmountChanged(null)),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.requestedAmount, isNull);
        expect(state.fiatEquivalent, isNull);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "clearing the amount rebuilds the URI without the previous amount",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convert(any(), any())).thenReturn(null);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(AmountChanged(Money.parse("1.0", CryptoCurrency.btc)));
        await Future.delayed(const Duration(milliseconds: 20));
        bloc.add(const AmountChanged(null));
        await Future.delayed(const Duration(milliseconds: 20));
      },
      verify: (_) {
        final amounts = verify(
          () => walletAddresses.paymentUriFor(any(), captureAny(), token: any(named: "token")),
        ).captured;
        expect(amounts.last, "");
      },
    );

    // Regression: satoshiForLightning display mode + lightning token used to
    // multiply the amount by 10^8 per modal round-trip. The modal parses sats
    // input against BTCLN; the bloc must keep the base-unit amount as it is.
    blocTest<ReceiveBloc, ReceiveState>(
      "amount denominated in BTCLN keeps its base units",
      setUp: () {
        wireDefaults(initialUri: _lightningUri);
        when(
          () => walletAddresses.paymentRequestUriFor(any(), any(), token: any(named: "token")),
        ).thenAnswer((_) async => _lightningUri);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AmountChanged(Money.tryParse("1235", CryptoCurrency.btcln, isBaseUnit: true)),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.requestedAmount, Money(BigInt.from(1235), CryptoCurrency.btcln));
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
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(AmountChanged(Money.parse("1.0", CryptoCurrency.btc)))
          ..add(AmountChanged(Money.parse("2.0", CryptoCurrency.btc)))
          ..add(AmountChanged(Money.parse("3.0", CryptoCurrency.btc)));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.requestedAmount, Money.parse("3.0", CryptoCurrency.btc));
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "a fiat amount is converted to crypto via FiatRateService",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convert(any(), any())).thenReturn(
          Money.parse("0.5", CryptoCurrency.btc),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const InputCurrencySelected(FiatCurrency.usd));
        await Future.delayed(const Duration(milliseconds: 30));
        bloc.add(AmountChanged(Money.parse("100", FiatCurrency.usd)));
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
      setUp: () => wireDefaults(
        walletCurrency: CryptoCurrency.eth,
        receivableTokens: const [CryptoCurrency.usdc],
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const TokenSelected(CryptoCurrency.usdc)),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(bloc.selectedToken(state), CryptoCurrency.usdc);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "ignores a token the wallet does not hold",
      setUp: () => wireDefaults(walletCurrency: CryptoCurrency.eth),
      build: buildBloc,
      act: (bloc) => bloc.add(const TokenSelected(CryptoCurrency.usdc)),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(bloc.selectedToken(state), isNull);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "clears tokenCurrency when preset matches walletCurrency",
      setUp: () => wireDefaults(walletCurrency: CryptoCurrency.eth),
      build: () => buildBloc(initialToken: CryptoCurrency.usdc),
      act: (bloc) => bloc.add(const TokenSelected(CryptoCurrency.eth)),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(bloc.selectedToken(state), isNull);
      },
    );
  });

  group("address type", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "holds the selection in state and never writes the wallet",
      setUp: wireDefaults,
      build: buildBloc,
      act: (bloc) => bloc.add(const AddressTypeSelected(_otherType)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect((bloc.state as ReceiveLoaded).addressType, _otherType);
        verify(() => walletAddresses.addressFor(_otherType)).called(1);
        verify(
          () => walletAddresses.paymentUriFor(_otherType, any(), token: any(named: "token")),
        ).called(1);
        verifyNever(() => walletAddresses.address = any());
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "switching to a Lightning type receives in BTCLN, and back to the wallet currency",
      setUp: wireDefaults,
      build: buildBloc,
      act: (bloc) async {
        await Future.delayed(const Duration(milliseconds: 10));
        stubPaymentUri(_lightningUri);
        bloc.add(const AddressTypeSelected(_otherType));
        await Future.delayed(const Duration(milliseconds: 10));
        expect((bloc.state as ReceiveLoaded).cryptoCurrency, CryptoCurrency.btcln);
        stubPaymentUri(_btcUri);
        bloc.add(const AddressTypeSelected(_defaultType));
        await Future.delayed(const Duration(milliseconds: 10));
      },
      verify: (bloc) {
        expect((bloc.state as ReceiveLoaded).cryptoCurrency, CryptoCurrency.btc);
      },
    );

    final presented = <ReceivePresentation>[];

    blocTest<ReceiveBloc, ReceiveState>(
      "a failed switch keeps the old type and is reported once",
      setUp: () {
        wireDefaults();
        presented.clear();
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.presentation.listen(presented.add);
        await Future.delayed(const Duration(milliseconds: 10));
        when(() => walletAddresses.addressListFor(_otherType)).thenThrow(Exception("boom"));
        bloc.add(const AddressTypeSelected(_otherType));
        await Future.delayed(const Duration(milliseconds: 10));
      },
      verify: (bloc) {
        expect((bloc.state as ReceiveLoaded).addressType, _defaultType);
        expect(presented, [isA<ReceiveAddressTypeChangeFailed>()]);
      },
    );
  });

  group("rotation", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "generates an active address of the selected type, isRotatingAddress false after",
      setUp: () {
        wireDefaults(canGenerate: true);
        when(
          () => (wallet as AddressGenerationWallet).generateNewAddress(
            any(),
            setAsActive: any(named: "setAsActive"),
          ),
        ).thenAnswer((_) async => "bc1qnew");
      },
      build: () => buildBloc(initialAddressType: _otherType),
      act: (bloc) => bloc.add(const AddressRotated()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.isRotatingAddress, isFalse);
        verify(
          () => (wallet as AddressGenerationWallet).generateNewAddress(
            _otherType,
            setAsActive: true,
          ),
        ).called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "droppable: back-to-back rotate events run once",
      setUp: () {
        wireDefaults(canGenerate: true);
        final completer = Completer<String>();
        when(
          () => (wallet as AddressGenerationWallet).generateNewAddress(
            any(),
            setAsActive: any(named: "setAsActive"),
          ),
        ).thenAnswer((_) => completer.future);
        Future.delayed(const Duration(milliseconds: 20), () => completer.complete("bc1qnew"));
      },
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(const AddressRotated())
          ..add(const AddressRotated());
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(
          () => (wallet as AddressGenerationWallet).generateNewAddress(
            any(),
            setAsActive: any(named: "setAsActive"),
          ),
        ).called(1);
      },
    );

    final presented = <ReceivePresentation>[];

    blocTest<ReceiveBloc, ReceiveState>(
      "a failed rotation clears isRotatingAddress and is reported once",
      setUp: () {
        wireDefaults(canGenerate: true);
        presented.clear();
        when(
          () => (wallet as AddressGenerationWallet).generateNewAddress(
            any(),
            setAsActive: any(named: "setAsActive"),
          ),
        ).thenThrow(Exception("no new address"));
      },
      build: buildBloc,
      act: (bloc) {
        bloc.presentation.listen(presented.add);
        bloc.add(const AddressRotated());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.isRotatingAddress, isFalse);
        expect(presented, [isA<ReceiveAddressRotationFailed>()]);
      },
    );
  });

  group("label", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "sets the label on the current entry through the wallet",
      setUp: () {
        wireDefaults(
          canGenerate: true,
          addressGroups: const [
            AddressGroup(entries: [_btcAddress]),
          ],
        );
        when(() => (wallet as AddressGenerationWallet).setAddressLabel(any(), any()))
            .thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LabelSubmitted("Donations")),
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(
          () => (wallet as AddressGenerationWallet).setAddressLabel(
            any(that: isA<AddressEntry>().having((e) => e.address, "address", "bc1qtestaddress")),
            "Donations",
          ),
        ).called(1);
      },
    );

    final presented = <ReceivePresentation>[];

    blocTest<ReceiveBloc, ReceiveState>(
      "a wallet without labels reports the failure once",
      setUp: () {
        wireDefaults();
        presented.clear();
      },
      build: buildBloc,
      act: (bloc) {
        bloc.presentation.listen(presented.add);
        bloc.add(const LabelSubmitted("Donations"));
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        expect(presented, [isA<ReceiveLabelUpdateFailed>()]);
      },
    );
  });

  group("infobox", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "marks the infobox dismissed once",
      setUp: wireDefaults,
      build: buildBloc,
      act: (bloc) => bloc.add(const InfoboxDismissed()),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final state = bloc.state as ReceiveLoaded;
        expect(state.isInfoboxDismissed, isTrue);
        verify(() => walletInfo.receiveInfoboxDismissed = true).called(1);
        verify(walletInfo.save).called(1);
      },
    );

    blocTest<ReceiveBloc, ReceiveState>(
      "no-op when already dismissed",
      setUp: () => wireDefaults(isInfoboxDismissed: true),
      build: buildBloc,
      act: (bloc) => bloc.add(const InfoboxDismissed()),
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verifyNever(walletInfo.save);
      },
    );
  });

  group("addresses page closed", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "refreshes address entry and payment URI for the selected type",
      setUp: wireDefaults,
      build: buildBloc,
      act: (bloc) async {
        await Future.delayed(const Duration(milliseconds: 10));
        when(() => walletAddresses.addressFor(any())).thenReturn("bc1qpicked");
        bloc.add(const AddressesPageClosed());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect((bloc.state as ReceiveLoaded).addressEntry.address, "bc1qpicked");
        verify(
          () => walletAddresses.paymentUriFor(_defaultType, any(), token: any(named: "token")),
        ).called(2);
      },
    );
  });

  group("streams", () {
    blocTest<ReceiveBloc, ReceiveState>(
      "fiat rate change refreshes fiatEquivalent when amount is set",
      setUp: () {
        wireDefaults();
        when(() => fiatRateService.convert(any(), any())).thenReturn(
          Money.parse("50000.00", FiatCurrency.usd),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(AmountChanged(Money.parse("1.0", CryptoCurrency.btc)));
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
      build: buildBloc,
      act: (_) async {
        await Future.delayed(const Duration(milliseconds: 20));
        stubPaymentUri(
          BitcoinURI(
            address: _btcAddress.address,
            amount: "",
            pjUri: "https://payjo.in/abc",
          ),
        );
        payjoinController.add(null);
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

class _FakeBalance extends Fake implements Balance {}
