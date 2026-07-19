import "dart:async";

import "package:bloc_test/bloc_test.dart";
import "package:cake_wallet/core/active_wallet_service.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/new-ui/viewmodels/addresses/addresses_bloc.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockAddressService extends Mock implements AddressService {}

class _MockActiveWalletService extends Mock implements ActiveWalletService {}

class _FakeWallet extends Fake implements WalletBase {}

AddressGroup _group(List<AddressEntry> entries, {AddressGroupHeader? header}) =>
    AddressGroup(header: header, entries: entries);

AddressEntry _entry(
  String address, {
  bool isHidden = false,
  bool isPrimary = false,
  String? label,
}) =>
    AddressEntry(
      address: address,
      isHidden: isHidden,
      isPrimary: isPrimary,
      label: label,
    );

void main() {
  late _MockAddressService addressService;
  late _MockActiveWalletService activeWalletService;
  late StreamController<WalletBase> walletChangesController;

  AddressesBloc buildBloc({bool showHidden = false}) => AddressesBloc(
        addressService: addressService,
        activeWalletService: activeWalletService,
        showHidden: showHidden,
      );

  void wireDefaults({
    List<AddressGroup> groups = const [],
    String currentAddress = "addr1",
    bool hasAccounts = false,
    AddressAccount? currentAccount,
    WalletType walletType = WalletType.bitcoin,
    bool isAutoGenerateSubaddressEnabled = false,
    bool canSetLabel = true,
    bool isSilentPayments = false,
  }) {
    when(() => addressService.computeAddressList()).thenReturn(groups);
    when(() => addressService.currentAddress).thenReturn(currentAddress);
    when(() => addressService.hasAccounts).thenReturn(hasAccounts);
    when(() => addressService.currentAccount).thenReturn(currentAccount);
    when(() => addressService.walletType).thenReturn(walletType);
    when(
      () => addressService.isAutoGenerateSubaddressEnabled,
    ).thenReturn(isAutoGenerateSubaddressEnabled);
    when(() => addressService.isBalanceAvailable).thenReturn(false);
    when(() => addressService.isReceivedAvailable).thenReturn(false);
    when(() => addressService.canSetLabel).thenReturn(canSetLabel);
    when(() => addressService.isSilentPayments).thenReturn(isSilentPayments);
    when(() => activeWalletService.walletChanges).thenAnswer((_) => walletChangesController.stream);
  }

  setUp(() {
    addressService = _MockAddressService();
    activeWalletService = _MockActiveWalletService();
    walletChangesController = StreamController<WalletBase>.broadcast();
  });

  tearDown(() async {
    await walletChangesController.close();
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
      "emits Failure when service throws",
      setUp: () {
        wireDefaults();
        when(() => addressService.computeAddressList()).thenThrow(Exception("boom"));
      },
      build: buildBloc,
      expect: () => [isA<AddressesLoading>(), isA<AddressesFailure>()],
    );
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
      "ActiveAddressSet delegates and refreshes activeAddress",
      setUp: () {
        wireDefaults();
        when(() => addressService.setActiveAddress(any())).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const ActiveAddressSet("addr2"));
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(() => addressService.setActiveAddress("addr2")).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressHideToggled delegates and refreshes groups",
      setUp: () {
        wireDefaults();
        when(() => addressService.setHidden(any(), hidden: any(named: "hidden")))
            .thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const AddressHideToggled("addr1", hidden: true));
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(() => addressService.setHidden("addr1", hidden: true)).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressLabelSet delegates",
      setUp: () {
        wireDefaults();
        when(() => addressService.setLabel(any(), any())).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const AddressLabelSet("addr1", "Donations"));
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(() => addressService.setLabel("addr1", "Donations")).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressAdded delegates",
      setUp: () {
        wireDefaults();
        when(() => addressService.addManualAddress(any())).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const AddressAdded("Savings"));
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(() => addressService.addManualAddress("Savings")).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressAdded is droppable: rapid taps add once",
      setUp: () {
        wireDefaults();
        final completer = Completer<void>();
        when(() => addressService.addManualAddress(any())).thenAnswer((_) => completer.future);
        Future.delayed(const Duration(milliseconds: 20), completer.complete);
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
        verify(() => addressService.addManualAddress("Savings")).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressDeleted delegates",
      setUp: () {
        wireDefaults();
        when(() => addressService.deleteSilentPaymentAddress(any())).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const AddressDeleted("sp1addr"));
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(() => addressService.deleteSilentPaymentAddress("sp1addr")).called(1);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "HiddenModeToggled flips the flag",
      setUp: wireDefaults,
      build: buildBloc,
      act: (bloc) async {
        await waitForLoaded(bloc);
        bloc.add(const HiddenModeToggled());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final state = bloc.state as AddressesLoaded;
        expect(state.showHidden, isTrue);
      },
    );

    blocTest<AddressesBloc, AddressesState>(
      "AddressHideToggled re-emits with fresh groups from service",
      setUp: () {
        var call = 0;
        when(() => addressService.computeAddressList()).thenAnswer((_) {
          call += 1;
          return call == 1
              ? [_group([_entry("addr1"), _entry("addr2")])]
              : [_group([_entry("addr1", isHidden: true), _entry("addr2")])];
        });
        when(() => addressService.currentAddress).thenReturn("addr1");
        when(() => addressService.hasAccounts).thenReturn(false);
        when(() => addressService.currentAccount).thenReturn(null);
        when(() => addressService.walletType).thenReturn(WalletType.bitcoin);
        when(() => addressService.isAutoGenerateSubaddressEnabled).thenReturn(false);
        when(() => addressService.isBalanceAvailable).thenReturn(false);
        when(() => addressService.isReceivedAvailable).thenReturn(false);
        when(() => addressService.canSetLabel).thenReturn(true);
        when(() => addressService.isSilentPayments).thenReturn(false);
        when(() => addressService.setHidden(any(), hidden: any(named: "hidden")))
            .thenAnswer((_) async {});
        when(() => activeWalletService.walletChanges)
            .thenAnswer((_) => walletChangesController.stream);
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

  group("wallet change", () {
    blocTest<AddressesBloc, AddressesState>(
      "re-initialises on wallet change",
      setUp: wireDefaults,
      build: buildBloc,
      act: (_) async {
        await Future.delayed(const Duration(milliseconds: 20));
        walletChangesController.add(_FakeWallet());
        await Future.delayed(const Duration(milliseconds: 30));
      },
      skip: 2,
      expect: () => [isA<AddressesLoading>(), isA<AddressesLoaded>()],
    );
  });
}
