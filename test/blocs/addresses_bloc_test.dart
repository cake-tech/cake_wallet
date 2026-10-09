import "dart:async";

import "package:bloc_test/bloc_test.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/new-ui/viewmodels/addresses/addresses_bloc.dart";
import "package:cw_core/address_entry.dart";
import "package:cw_core/address_generation_wallet.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockAddressService extends Mock implements AddressService {}

class _MockWallet extends Mock implements WalletBase {}

class _MockGeneratingWallet extends Mock implements WalletBase, AddressGenerationWallet {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _MockWalletInfo extends Mock implements WalletInfo {}

class _Option implements ReceivePageOption {
  const _Option(this.value);

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
  bool get canRotateAddress => true;
}

const _defaultType = _Option("default-type");
const _pickedType = _Option("picked-type");

AddressGroup _group(List<AddressEntry> entries, {AddressGroupHeader? header}) =>
    AddressGroup(header: header, entries: entries);

AddressEntry _entry(
  String address, {
  bool isHidden = false,
  String? label,
}) =>
    AddressEntry(
      address: address,
      isHidden: isHidden,
      label: label,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const AddressEntry(address: "fallback"));
    registerFallbackValue(_defaultType);
    registerFallbackValue(_MockWallet());
  });

  late _MockAddressService addressService;
  late _MockWalletAddresses walletAddresses;
  late WalletBase wallet;
  late Set<String> hiddenAddresses;

  AddressesBloc buildBloc({bool showHidden = false, ReceivePageOption? addressType}) =>
      AddressesBloc(
        wallet: wallet,
        addressService: addressService,
        addressType: addressType,
        showHidden: showHidden,
      );

  void wireDefaults({
    List<AddressGroup> groups = const [],
    String currentAddress = "addr1",
    WalletType walletType = WalletType.bitcoin,
    bool isAutoGenerateSubaddressEnabled = false,
    bool canHide = true,
    bool canGenerate = true,
    bool? isMultiAccountsEnabled,
    bool hasNativeAccounts = false,
    String? accountLabel,
  }) {
    final WalletBase mockWallet = canGenerate ? _MockGeneratingWallet() : _MockWallet();
    final walletInfo = _MockWalletInfo();
    when(() => walletInfo.isMultiAccountsEnabled).thenReturn(isMultiAccountsEnabled);
    when(() => walletInfo.internalId).thenReturn(7);
    when(() => mockWallet.type).thenReturn(walletType);
    when(() => mockWallet.name).thenReturn("wallet-a");
    when(() => mockWallet.walletAddresses).thenReturn(walletAddresses);
    when(() => mockWallet.walletInfo).thenReturn(walletInfo);
    when(() => mockWallet.hasNativeAccounts).thenReturn(hasNativeAccounts);
    wallet = mockWallet;

    when(() => walletAddresses.defaultAddressType).thenReturn(_defaultType);
    when(() => walletAddresses.addressListFor(any())).thenReturn(groups);
    when(() => walletAddresses.addressFor(any())).thenReturn(currentAddress);
    when(() => walletAddresses.canHideAddresses).thenReturn(canHide);
    when(() => walletAddresses.hiddenAddresses).thenReturn(hiddenAddresses);
    when(walletAddresses.saveAddressesInBox).thenAnswer((_) async {});
    when(() => addressService.isAutoGenerateSubaddressEnabled(any(), any()))
        .thenReturn(isAutoGenerateSubaddressEnabled);
    when(walletAddresses.loadAccountLabel).thenAnswer((_) async => accountLabel);
    when(() => walletAddresses.currentAccountIndex).thenReturn(0);
  }

  setUp(() {
    addressService = _MockAddressService();
    walletAddresses = _MockWalletAddresses();
    hiddenAddresses = <String>{};
  });

  Future<void> waitForLoaded(AddressesBloc bloc) =>
      bloc.stream.firstWhere((s) => s is AddressesLoaded).then((_) {});

  group("initialization", () {
    blocTest<AddressesBloc, AddressesState>(
      "emits Loading then Loaded on init",
      setUp: wireDefaults,
      build: buildBloc,
      expect: () => [isA<AddressesLoading>(), isA<AddressesLoaded>()],
    );

    blocTest<AddressesBloc, AddressesState>(
      "carries showHidden through to state",
      setUp: wireDefaults,
      build: () => buildBloc(showHidden: true),
      verify: (bloc) {
        final state = bloc.state as AddressesLoaded;
        expect(state.showHidden, isTrue);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "emits Failure when the wallet list throws",
      setUp: () {
        wireDefaults();
        when(() => walletAddresses.addressListFor(any())).thenThrow(Exception("boom"));
      },
      build: buildBloc,
      expect: () => [isA<AddressesLoading>(), isA<AddressesFailure>()],
    );

    blocTest<AddressesBloc, AddressesState>(
      "lists the wallet's default type when none is passed",
      setUp: () => wireDefaults(groups: [
        _group([_entry("addr1")]),
      ]),
      build: buildBloc,
      verify: (bloc) {
        expect(bloc.addressType, _defaultType);
        verify(() => walletAddresses.addressListFor(_defaultType)).called(1);
        verify(() => walletAddresses.addressFor(_defaultType)).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "offers the wallet's one address when the type has no list",
      setUp: () => wireDefaults(currentAddress: "0xsingleaddress"),
      build: buildBloc,
      verify: (bloc) {
        final groups = (bloc.state as AddressesLoaded).groups;
        expect(groups, hasLength(1));
        expect(groups.single.entries.map((e) => e.address), ["0xsingleaddress"]);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "lists the type passed in by the receive page",
      setUp: wireDefaults,
      build: () => buildBloc(addressType: _pickedType),
      verify: (bloc) {
        expect(bloc.addressType, _pickedType);
        verify(() => walletAddresses.addressListFor(_pickedType)).called(1);
        verifyNever(() => walletAddresses.addressListFor(_defaultType));
      },
    );
  });

  group("capabilities", () {
    test("canGenerateAddresses follows AddressGenerationWallet", () {
      wireDefaults(canGenerate: false);
      final plain = buildBloc();
      expect(plain.canGenerateAddresses, isFalse);
      plain.close();

      wireDefaults(canGenerate: true);
      final generating = buildBloc();
      expect(generating.canGenerateAddresses, isTrue);
      generating.close();
    });

    test("canHide reads walletAddresses.canHideAddresses", () {
      wireDefaults(canHide: false);
      final bloc = buildBloc();
      expect(bloc.canHide, isFalse);
      bloc.close();
    });

    test("account header carries the current account label when multi-accounts is on", () async {
      wireDefaults(isMultiAccountsEnabled: true, accountLabel: "Savings account");
      final bloc = buildBloc();
      await waitForLoaded(bloc);
      expect(bloc.showsAccountHeader, isTrue);
      expect(bloc.accountLabel, "Savings account");
      await bloc.close();
    });

    test("account header stays hidden when multi-accounts is off or unset", () async {
      wireDefaults(isMultiAccountsEnabled: false, accountLabel: "Savings account");
      final off = buildBloc();
      await waitForLoaded(off);
      expect(off.showsAccountHeader, isFalse);
      expect(off.accountLabel, isNull);
      await off.close();

      wireDefaults(isMultiAccountsEnabled: null, accountLabel: "Savings account");
      final unset = buildBloc();
      await waitForLoaded(unset);
      expect(unset.showsAccountHeader, isFalse);
      expect(unset.accountLabel, isNull);
      verifyNever(walletAddresses.loadAccountLabel);
      await unset.close();
    });

    test("hasNativeAccounts follows the wallet", () {
      wireDefaults(hasNativeAccounts: true);
      final native = buildBloc();
      expect(native.hasNativeAccounts, isTrue);
      native.close();

      wireDefaults();
      final plain = buildBloc();
      expect(plain.hasNativeAccounts, isFalse);
      plain.close();
    });

    test("showAddManualAddresses needs generation and auto-generate off", () {
      wireDefaults(isAutoGenerateSubaddressEnabled: false);
      final manual = buildBloc();
      expect(manual.showAddManualAddresses, isTrue);
      manual.close();

      wireDefaults(isAutoGenerateSubaddressEnabled: true);
      final autoGen = buildBloc();
      expect(autoGen.showAddManualAddresses, isFalse);
      autoGen.close();

      wireDefaults(isAutoGenerateSubaddressEnabled: false, canGenerate: false);
      final noGeneration = buildBloc();
      expect(noGeneration.showAddManualAddresses, isFalse);
      noGeneration.close();
    });

    test("showAddManualAddresses stays on for native account wallets with auto-generate on", () {
      wireDefaults(hasNativeAccounts: true, isAutoGenerateSubaddressEnabled: true);
      final bloc = buildBloc();
      expect(bloc.showAddManualAddresses, isTrue);
      bloc.close();
    });

    test("multi-accounts alone does not turn on manual addresses with auto-generate on", () {
      wireDefaults(
        isMultiAccountsEnabled: true,
        accountLabel: "Savings account",
        isAutoGenerateSubaddressEnabled: true,
      );
      final bloc = buildBloc();
      expect(bloc.showAddManualAddresses, isFalse);
      bloc.close();
    });
  });

  group("search", () {
    blocTest<AddressesBloc, AddressesState>(
      "updates searchTerm",
      setUp: () => wireDefaults(
        groups: [
          _group([_entry("bc1qalpha"), _entry("bc1qbravo")]),
        ],
      ),
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const SearchTermEntered("alpha"));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final state = bloc.state as AddressesLoaded;
        expect(state.searchTerm, "alpha");
        expect(state.displayableGroups.first.entries.single.address, "bc1qalpha");
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "displayableGroups excludes hidden when showHidden is false",
      setUp: () => wireDefaults(
        groups: [
          _group([_entry("visible"), _entry("hidden1", isHidden: true)]),
        ],
      ),
      build: buildBloc,
      verify: (bloc) {
        final state = bloc.state as AddressesLoaded;
        final displayed = state.displayableGroups.expand((g) => g.entries).toList();
        expect(displayed.map((e) => e.address), ["visible"]);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "displayableGroups includes only hidden when showHidden is true",
      setUp: () => wireDefaults(
        groups: [
          _group([_entry("visible"), _entry("hidden1", isHidden: true)]),
        ],
      ),
      build: () => buildBloc(showHidden: true),
      verify: (bloc) {
        final state = bloc.state as AddressesLoaded;
        final displayed = state.displayableGroups.expand((g) => g.entries).toList();
        expect(displayed.map((e) => e.address), ["hidden1"]);
      },
    );
  });

  group("mutations", () {
    blocTest<AddressesBloc, AddressesState>(
      "ActiveAddressSet writes the wallet address and reads back the type's current one",
      setUp: () => wireDefaults(currentAddress: "addr1"),
      build: () => buildBloc(addressType: _pickedType),
      act: (bloc) async {
        await waitForLoaded(bloc);
        when(() => walletAddresses.addressFor(_pickedType)).thenReturn("addr2");
        bloc.add(const ActiveAddressSet("addr2"));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        verify(() => walletAddresses.address = "addr2").called(1);
        expect((bloc.state as AddressesLoaded).activeAddress, "addr2");
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressHideToggled adds to hiddenAddresses and saves",
      setUp: wireDefaults,
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const AddressHideToggled("addr1", hidden: true));
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        expect(hiddenAddresses, {"addr1"});
        verify(walletAddresses.saveAddressesInBox).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressHideToggled with hidden = false removes from hiddenAddresses",
      setUp: () {
        wireDefaults();
        hiddenAddresses.addAll({"addr1", "addr2"});
      },
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const AddressHideToggled("addr1", hidden: false));
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        expect(hiddenAddresses, {"addr2"});
        verify(walletAddresses.saveAddressesInBox).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressLabelSet goes to the wallet",
      setUp: () {
        wireDefaults();
        when(() => (wallet as AddressGenerationWallet).setAddressLabel(any(), any()))
            .thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(AddressLabelSet(_entry("addr1"), "Donations"));
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(
          () => (wallet as AddressGenerationWallet).setAddressLabel(
            any(that: isA<AddressEntry>().having((e) => e.address, "address", "addr1")),
            "Donations",
          ),
        ).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressAdded generates an address of the page's type, not set as active",
      setUp: () {
        wireDefaults();
        when(
          () => (wallet as AddressGenerationWallet).generateNewAddress(
            any(),
            label: any(named: "label"),
          ),
        ).thenAnswer((_) async => "addr-new");
      },
      build: () => buildBloc(addressType: _pickedType),
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const AddressAdded("Savings"));
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(
          () => (wallet as AddressGenerationWallet).generateNewAddress(
            _pickedType,
            label: "Savings",
          ),
        ).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressAdded is droppable: rapid taps add once",
      setUp: () {
        wireDefaults();
        final completer = Completer<String>();
        when(
          () => (wallet as AddressGenerationWallet).generateNewAddress(
            any(),
            label: any(named: "label"),
          ),
        ).thenAnswer((_) => completer.future);
        Future.delayed(const Duration(milliseconds: 20), () => completer.complete("addr-new"));
      },
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc
          ..add(const AddressAdded("Savings"))
          ..add(const AddressAdded("Savings"));
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(
          () => (wallet as AddressGenerationWallet).generateNewAddress(
            any(),
            label: "Savings",
          ),
        ).called(1);
      },
    );

    final presented = <AddressesPresentation>[];

    blocTest<AddressesBloc, AddressesState>(
      "a failed add is reported once as a presentation event and clears isSaving",
      setUp: () {
        wireDefaults();
        presented.clear();
        when(
          () => (wallet as AddressGenerationWallet).generateNewAddress(
            any(),
            label: any(named: "label"),
          ),
        ).thenThrow(Exception("no new address"));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.presentation.listen(presented.add);
        await waitForLoaded(bloc);
        bloc.add(const AddressAdded("Savings"));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final state = bloc.state as AddressesLoaded;
        expect(state.isSaving, isFalse);
        expect(presented, [isA<AddressesAddFailed>()]);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressHideToggled re-emits with fresh groups from the wallet",
      setUp: () {
        wireDefaults();
        int call = 0;
        when(() => walletAddresses.addressListFor(any())).thenAnswer((_) {
          call += 1;
          return call == 1
              ? [
                  _group([_entry("addr1"), _entry("addr2")]),
                ]
              : [
                  _group([_entry("addr1", isHidden: true), _entry("addr2")]),
                ];
        });
      },
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const AddressHideToggled("addr1", hidden: true));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final state = bloc.state as AddressesLoaded;
        expect(state.groups.first.entries.first.isHidden, isTrue);
      },
    );
  });
}
