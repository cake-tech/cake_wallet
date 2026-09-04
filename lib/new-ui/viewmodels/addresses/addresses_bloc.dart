import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/core/active_wallet_service.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:equatable/equatable.dart";

part "addresses_event.dart";
part "addresses_state.dart";

class AddressesBloc extends Bloc<AddressesEvent, AddressesState> {
  AddressesBloc({
    required this.addressService,
    required this.activeWalletService,
    bool showHidden = false,
  }) : super(const AddressesLoading()) {
    on<AddressesOpened>(_onOpened, transformer: restartable());
    on<SearchTermEntered>(_onSearch, transformer: restartable());
    on<ActiveAddressSet>(_onActiveAddressSet, transformer: sequential());
    on<AddressHideToggled>(_onHideToggled, transformer: sequential());
    on<AddressLabelSet>(_onLabelSet, transformer: sequential());
    on<AddressAdded>(_onAddressAdded, transformer: droppable());
    on<AddressDeleted>(_onDeleted, transformer: sequential());
    on<AddressListRefreshed>(_onListRefreshed, transformer: sequential());
    on<_WalletChanged>(_onWalletChanged, transformer: restartable());

    _walletSub = activeWalletService.walletChanges.listen((_) {
      if (!isClosed) {
        add(const _WalletChanged());
      }
    });

    add(AddressesOpened(showHidden: showHidden));
  }

  final AddressService addressService;
  final ActiveWalletService activeWalletService;

  late final StreamSubscription<WalletBase> _walletSub;

  @override
  Future<void> close() async {
    await _walletSub.cancel();
    return super.close();
  }

  Future<void> _onOpened(AddressesOpened event, Emitter<AddressesState> emit) async {
    emit(const AddressesLoading());
    try {
      emit(_buildLoaded(showHidden: event.showHidden));
    } catch (e) {
      printV("AddressesBloc _onOpened failed: $e");
      emit(const AddressesFailure(AddressesFailureCode.addressListUnavailable));
    }
  }

  Future<void> _onSearch(SearchTermEntered event, Emitter<AddressesState> emit) async {
    final loaded = state;
    if (loaded is! AddressesLoaded) {
      return;
    }
    emit(loaded.copyWith(searchTerm: event.term));
  }

  Future<void> _onActiveAddressSet(ActiveAddressSet event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    emit(initial.copyWith(clearFailureCode: true));
    try {
      await addressService.setActiveAddress(event.address);
    } catch (e) {
      printV("AddressesBloc setActiveAddress failed: $e");
      _emitFailure(emit, initial.walletId);
      return;
    }
    if (isClosed) {
      return;
    }
    if (state case final AddressesLoaded loaded when loaded.walletId == initial.walletId) {
      emit(loaded.copyWith(activeAddress: addressService.currentAddress));
    }
  }

  Future<void> _onHideToggled(AddressHideToggled event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    emit(initial.copyWith(isSaving: true, clearFailureCode: true));
    try {
      await addressService.setHidden(event.address, hidden: event.hidden);
    } catch (e) {
      printV("AddressesBloc setHidden failed: $e");
      _emitFailure(emit, initial.walletId);
      return;
    }
    _refreshGroups(emit, initial.walletId);
  }

  Future<void> _onLabelSet(AddressLabelSet event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    emit(initial.copyWith(isSaving: true, clearFailureCode: true));
    try {
      await addressService.setLabel(event.address, event.label);
    } catch (e) {
      printV("AddressesBloc setLabel failed: $e");
      _emitFailure(emit, initial.walletId);
      return;
    }
    _refreshGroups(emit, initial.walletId);
  }

  Future<void> _onAddressAdded(AddressAdded event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    emit(initial.copyWith(isSaving: true, clearFailureCode: true));
    try {
      await addressService.addManualAddress(event.label);
    } catch (e) {
      printV("AddressesBloc addManualAddress failed: $e");
      _emitFailure(emit, initial.walletId);
      return;
    }
    _refreshGroups(emit, initial.walletId);
  }

  Future<void> _onDeleted(AddressDeleted event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    emit(initial.copyWith(isSaving: true, clearFailureCode: true));
    try {
      await addressService.deleteSilentPaymentAddress(event.address);
    } catch (e) {
      printV("AddressesBloc deleteSilentPaymentAddress failed: $e");
      _emitFailure(emit, initial.walletId);
      return;
    }
    _refreshGroups(emit, initial.walletId);
  }

  void _emitFailure(Emitter<AddressesState> emit, String expectedWalletId) {
    if (isClosed) {
      return;
    }
    if (state case final AddressesLoaded loaded when loaded.walletId == expectedWalletId) {
      emit(
        loaded.copyWith(
          isSaving: false,
          failureCode: AddressesFailureCode.saveFailed,
        ),
      );
    }
  }

  void _refreshGroups(Emitter<AddressesState> emit, String expectedWalletId) {
    if (isClosed) {
      return;
    }
    if (state case final AddressesLoaded loaded when loaded.walletId == expectedWalletId) {
      try {
        emit(
          loaded.copyWith(
            groups: addressService.computeAddressList(),
            activeAddress: addressService.currentAddress,
            hasHiddenAddresses: addressService.hasHiddenAddresses,
            accountLabel: addressService.accountLabel,
            isSaving: false,
          ),
        );
      } catch (e) {
        printV("AddressesBloc refresh failed: $e");
        emit(loaded.copyWith(isSaving: false));
      }
    }
  }

  Future<void> _onListRefreshed(
    AddressListRefreshed event,
    Emitter<AddressesState> emit,
  ) async {
    final loaded = state;
    if (loaded is! AddressesLoaded) {
      return;
    }
    try {
      emit(
        loaded.copyWith(
          groups: addressService.computeAddressList(),
          hasHiddenAddresses: addressService.hasHiddenAddresses,
          accountLabel: addressService.accountLabel,
        ),
      );
    } catch (e) {
      printV("AddressesBloc list refresh failed: $e");
    }
  }

  Future<void> _onWalletChanged(_WalletChanged event, Emitter<AddressesState> emit) async {
    if (isClosed) {
      return;
    }
    final showHidden = switch (state) {
      final AddressesLoaded loaded => loaded.showHidden,
      _ => false,
    };
    add(AddressesOpened(showHidden: showHidden));
  }

  AddressesLoaded _buildLoaded({required bool showHidden}) => AddressesLoaded(
        groups: addressService.computeAddressList(),
        activeAddress: addressService.currentAddress,
        searchTerm: "",
        showHidden: showHidden,
        hasAccounts: addressService.hasAccounts,
        walletId: addressService.walletId,
        walletType: addressService.walletType,
        walletName: addressService.walletName,
        accountLabel: addressService.accountLabel,
        hasHiddenAddresses: addressService.hasHiddenAddresses,
        showAddManualAddresses: !addressService.isAutoGenerateSubaddressEnabled ||
            const {WalletType.monero, WalletType.wownero}.contains(addressService.walletType),
        canSetLabel: addressService.canSetLabel,
        canHide: addressService.canHide,
      );
}
