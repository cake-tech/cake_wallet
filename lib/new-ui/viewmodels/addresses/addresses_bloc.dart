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
    on<ActiveAddressSet>(_onActiveAddressSet);
    on<AddressHideToggled>(_onHideToggled);
    on<AddressLabelSet>(_onLabelSet);
    on<AddressAdded>(_onAddressAdded);
    on<AddressDeleted>(_onDeleted);
    on<HiddenModeToggled>(_onHiddenModeToggled);
    on<_WalletChanged>(_onWalletChanged);

    _walletSub = activeWalletService.walletChanges.listen((_) => add(const _WalletChanged()));

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
    final loaded = state;
    if (loaded is! AddressesLoaded) {
      return;
    }

    await addressService.setActiveAddress(event.address);
    if (state case final AddressesLoaded loaded) {
      emit(loaded.copyWith(activeAddress: addressService.currentAddress));
    }
  }

  Future<void> _onHideToggled(AddressHideToggled event, Emitter<AddressesState> emit) async {
    final loaded = state;
    if (loaded is! AddressesLoaded) {
      return;
    }

    await addressService.setHidden(event.address, hidden: event.hidden);
    if (state case final AddressesLoaded loaded) {
      emit(loaded.copyWith(groups: addressService.computeAddressList()));
    }
  }

  Future<void> _onLabelSet(AddressLabelSet event, Emitter<AddressesState> emit) async {
    final loaded = state;
    if (loaded is! AddressesLoaded) {
      return;
    }

    await addressService.setLabel(event.address, event.label);
    if (state case final AddressesLoaded loaded) {
      emit(loaded.copyWith(groups: addressService.computeAddressList()));
    }
  }

  Future<void> _onAddressAdded(AddressAdded event, Emitter<AddressesState> emit) async {
    final loaded = state;
    if (loaded is! AddressesLoaded) {
      return;
    }

    await addressService.addManualAddress(event.label);
    if (state case final AddressesLoaded loaded) {
      emit(loaded.copyWith(groups: addressService.computeAddressList()));
    }
  }

  Future<void> _onDeleted(AddressDeleted event, Emitter<AddressesState> emit) async {
    final loaded = state;
    if (loaded is! AddressesLoaded) {
      return;
    }

    await addressService.deleteSilentPaymentAddress(event.address);
    if (state case final AddressesLoaded loaded) {
      emit(loaded.copyWith(groups: addressService.computeAddressList()));
    }
  }

  Future<void> _onHiddenModeToggled(
    HiddenModeToggled event,
    Emitter<AddressesState> emit,
  ) async {
    final loaded = state;
    if (loaded is! AddressesLoaded) {
      return;
    }
    emit(loaded.copyWith(showHidden: !loaded.showHidden));
  }

  Future<void> _onWalletChanged(_WalletChanged event, Emitter<AddressesState> emit) async {
    final currentShowHidden =
        state is AddressesLoaded ? (state as AddressesLoaded).showHidden : false;
    add(AddressesOpened(showHidden: currentShowHidden));
  }

  AddressesLoaded _buildLoaded({required bool showHidden}) => AddressesLoaded(
        groups: addressService.computeAddressList(),
        activeAddress: addressService.currentAddress,
        searchTerm: "",
        showHidden: showHidden,
        hasAccounts: addressService.hasAccounts,
        currentAccount: addressService.currentAccount,
        walletType: addressService.walletType,
        showAddManualAddresses: !addressService.isAutoGenerateSubaddressEnabled ||
            const {WalletType.monero, WalletType.wownero}.contains(addressService.walletType),
      );
}
