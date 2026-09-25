import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/active_wallet_service.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";

part "addresses_event.dart";
part "addresses_presentation.dart";
part "addresses_state.dart";

class AddressesBloc extends Bloc<AddressesEvent, AddressesState>
    with BlocPresentationMixin<AddressesState, AddressesPresentation> {
  AddressesBloc({
    required this.addressService,
    required this.activeWalletService,
    this.showHidden = false,
  }) : super(const AddressesLoading()) {
    on<Init>(_init, transformer: restartable());
    on<SearchTermEntered>(_onSearch, transformer: restartable());
    on<ActiveAddressSet>(_onActiveAddressSet, transformer: sequential());
    on<AddressHideToggled>(_onHideToggled, transformer: sequential());
    on<AddressLabelSet>(_onLabelSet, transformer: sequential());
    on<AddressAdded>(_onAddressAdded, transformer: droppable());
    on<AddressListRefreshed>(_onListRefreshed, transformer: sequential());
    on<_WalletChanged>(_onWalletChanged, transformer: restartable());

    _walletSub = activeWalletService.walletChanges.listen((_) {
      if (!isClosed) {
        add(const _WalletChanged());
      }
    });

    add(const Init());
  }

  final AddressService addressService;
  final ActiveWalletService activeWalletService;
  final bool showHidden;

  late final StreamSubscription<WalletBase> _walletSub;

  String get accountLabel => addressService.accountLabel;

  @override
  Future<void> close() async {
    await _walletSub.cancel();
    return super.close();
  }

  Future<void> _init(Init event, Emitter<AddressesState> emit) async {
    emit(const AddressesLoading());
    try {
      emit(_buildLoaded());
    } catch (e) {
      printV("AddressesBloc _init failed: $e");
      emit(const AddressesFailure());
    }
  }

  Future<void> _onSearch(SearchTermEntered event, Emitter<AddressesState> emit) async {
    if (state case final AddressesLoaded loaded) {
      emit(loaded.copyWith(searchTerm: event.term));
    }
  }

  Future<void> _onActiveAddressSet(ActiveAddressSet event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    try {
      await addressService.setActiveAddress(event.address);
    } catch (e) {
      printV("AddressesBloc setActiveAddress failed: $e");
      _fail(emit, initial.walletId, const AddressesUpdateFailed());
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

    emit(initial.copyWith(isSaving: true));
    try {
      await addressService.setHidden(event.address, hidden: event.hidden);
    } catch (e) {
      printV("AddressesBloc setHidden failed: $e");
      _fail(emit, initial.walletId, const AddressesUpdateFailed());
      return;
    }
    _refreshGroups(emit, initial.walletId);
  }

  Future<void> _onLabelSet(AddressLabelSet event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    emit(initial.copyWith(isSaving: true));
    try {
      await addressService.setLabel(event.entry, event.label);
    } catch (e) {
      printV("AddressesBloc setLabel failed: $e");
      _fail(emit, initial.walletId, const AddressesLabelUpdateFailed());
      return;
    }
    _refreshGroups(emit, initial.walletId);
  }

  Future<void> _onAddressAdded(AddressAdded event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    emit(initial.copyWith(isSaving: true));
    try {
      await addressService.addManualAddress(event.label);
    } catch (e) {
      printV("AddressesBloc addManualAddress failed: $e");
      _fail(emit, initial.walletId, const AddressesAddFailed());
      return;
    }
    _refreshGroups(emit, initial.walletId);
  }

  void _fail(
    Emitter<AddressesState> emit,
    String expectedWalletId,
    AddressesPresentation presentation,
  ) {
    if (isClosed) {
      return;
    }
    if (state case final AddressesLoaded loaded when loaded.walletId == expectedWalletId) {
      emit(loaded.copyWith(isSaving: false));
      emitPresentation(presentation);
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
          activeAddress: addressService.currentAddress,
        ),
      );
    } catch (e) {
      printV("AddressesBloc list refresh failed: $e");
    }
  }

  Future<void> _onWalletChanged(_WalletChanged event, Emitter<AddressesState> emit) async {
    if (!isClosed) {
      add(const Init());
    }
  }

  AddressesLoaded _buildLoaded() {
    final wallet = addressService.wallet;
    return AddressesLoaded(
      groups: addressService.computeAddressList(),
      activeAddress: addressService.currentAddress,
      searchTerm: "",
      showHidden: showHidden,
      hasAccounts: addressService.hasAccounts,
      walletId: wallet.id,
      walletType: wallet.type,
      walletName: wallet.name,
      showAddManualAddresses:
          !addressService.isAutoGenerateSubaddressEnabled || wallet.type == WalletType.monero,
      canSetLabel: addressService.canSetLabel,
      canHide: addressService.canHide,
    );
  }
}
