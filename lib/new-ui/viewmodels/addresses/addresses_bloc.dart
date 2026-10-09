import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/address_entry.dart";
import "package:cw_core/address_generation_wallet.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";

part "addresses_event.dart";
part "addresses_presentation.dart";
part "addresses_state.dart";

class AddressesBloc extends Bloc<AddressesEvent, AddressesState>
    with BlocPresentationMixin<AddressesState, AddressesPresentation> {
  AddressesBloc({
    required this.wallet,
    required this.addressService,
    ReceivePageOption? addressType,
    this.showHidden = false,
  })  : addressType = addressType ?? wallet.walletAddresses.defaultAddressType,
        super(const AddressesLoading()) {
    on<Init>(_init, transformer: restartable());
    on<SearchTermEntered>(_onSearch, transformer: restartable());
    on<ActiveAddressSet>(_onActiveAddressSet, transformer: sequential());
    on<AddressHideToggled>(_onHideToggled, transformer: sequential());
    on<AddressLabelSet>(_onLabelSet, transformer: sequential());
    on<AddressAdded>(_onAddressAdded, transformer: droppable());
    on<AddressListRefreshed>(_onListRefreshed, transformer: sequential());

    add(const Init());
  }

  final WalletBase wallet;
  final AddressService addressService;
  final ReceivePageOption addressType;
  final bool showHidden;

  String get walletName => wallet.name;

  WalletType get walletType => wallet.type;

  bool get hasNativeAccounts => wallet.hasNativeAccounts;

  bool get showsAccountHeader => wallet.walletInfo.isMultiAccountsEnabled == true;

  String? _accountLabel;

  String? get accountLabel => _accountLabel;

  CardDesign? _accountCardDesign;

  CardDesign get accountCardDesign => _accountCardDesign ?? CardDesign.genericDefault;

  Money? get accountBalance => wallet.balance[wallet.currency]?.available;

  bool get canGenerateAddresses => wallet is AddressGenerationWallet;

  bool get canHide => wallet.walletAddresses.canHideAddresses;

  bool get showAddManualAddresses =>
      canGenerateAddresses &&
      (!addressService.isAutoGenerateSubaddressEnabled(wallet, addressType) || hasNativeAccounts);

  Future<void> _init(Init event, Emitter<AddressesState> emit) async {
    emit(const AddressesLoading());
    if (showsAccountHeader) {
      await _loadAccountHeader();
    }
    try {
      emit(
        AddressesLoaded(
          groups: _groups(),
          activeAddress: wallet.walletAddresses.addressFor(addressType),
          searchTerm: "",
          showHidden: showHidden,
        ),
      );
    } catch (e) {
      printV("AddressesBloc _init failed: $e");
      emit(const AddressesFailure());
    }
  }

  Future<void> _loadAccountHeader() async {
    try {
      _accountLabel = await wallet.walletAddresses.loadAccountLabel();
    } catch (e) {
      printV("AddressesBloc account label load failed: $e");
    }

    try {
      final walletInfoId = wallet.walletInfo.internalId;
      final accountIndex = wallet.walletAddresses.currentAccountIndex;
      // Account 0 can still hold its style under the wallet-wide -1 index from before accounts.
      final settings = await BalanceCardStyleSettings.get(walletInfoId, accountIndex) ??
          (accountIndex == 0 ? await BalanceCardStyleSettings.get(walletInfoId, -1) : null);
      _accountCardDesign = CardDesign.fromStyleSettings(settings, wallet.currency);
    } catch (e) {
      printV("AddressesBloc card design load failed: $e");
    }
  }

  void _onSearch(SearchTermEntered event, Emitter<AddressesState> emit) {
    if (state case final AddressesLoaded loaded) {
      emit(loaded.copyWith(searchTerm: event.term));
    }
  }

  void _onActiveAddressSet(ActiveAddressSet event, Emitter<AddressesState> emit) {
    if (state case final AddressesLoaded loaded) {
      wallet.walletAddresses.address = event.address;
      emit(loaded.copyWith(activeAddress: wallet.walletAddresses.addressFor(addressType)));
    }
  }

  Future<void> _onHideToggled(AddressHideToggled event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    emit(initial.copyWith(isSaving: true));
    try {
      final addresses = wallet.walletAddresses;
      if (event.hidden) {
        addresses.hiddenAddresses.add(event.address);
      } else {
        addresses.hiddenAddresses.remove(event.address);
      }
      await addresses.saveAddressesInBox();
    } catch (e) {
      printV("AddressesBloc setHidden failed: $e");
      _fail(emit, const AddressesUpdateFailed());
      return;
    }
    _refreshGroups(emit);
  }

  Future<void> _onLabelSet(AddressLabelSet event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    emit(initial.copyWith(isSaving: true));
    try {
      await (wallet as AddressGenerationWallet).setAddressLabel(event.entry, event.label);
    } catch (e) {
      printV("AddressesBloc setLabel failed: $e");
      _fail(emit, const AddressesLabelUpdateFailed());
      return;
    }
    _refreshGroups(emit);
  }

  Future<void> _onAddressAdded(AddressAdded event, Emitter<AddressesState> emit) async {
    final initial = state;
    if (initial is! AddressesLoaded) {
      return;
    }

    emit(initial.copyWith(isSaving: true));
    try {
      await (wallet as AddressGenerationWallet).generateNewAddress(addressType, label: event.label);
    } catch (e) {
      printV("AddressesBloc add address failed: $e");
      _fail(emit, const AddressesAddFailed());
      return;
    }
    _refreshGroups(emit);
  }

  void _fail(Emitter<AddressesState> emit, AddressesPresentation presentation) {
    if (isClosed) {
      return;
    }
    if (state case final AddressesLoaded loaded) {
      emit(loaded.copyWith(isSaving: false));
      emitPresentation(presentation);
    }
  }

  void _refreshGroups(Emitter<AddressesState> emit) {
    if (isClosed) {
      return;
    }
    if (state case final AddressesLoaded loaded) {
      try {
        emit(
          loaded.copyWith(
            groups: _groups(),
            activeAddress: wallet.walletAddresses.addressFor(addressType),
            isSaving: false,
          ),
        );
      } catch (e) {
        printV("AddressesBloc refresh failed: $e");
        emit(loaded.copyWith(isSaving: false));
      }
    }
  }

  List<AddressGroup> _groups() {
    final groups = wallet.walletAddresses.addressListFor(addressType);
    if (groups.isNotEmpty) {
      return groups;
    }

    final address = wallet.walletAddresses.addressFor(addressType);
    return [
      AddressGroup(entries: [AddressEntry(address: address)]),
    ];
  }

  void _onListRefreshed(AddressListRefreshed event, Emitter<AddressesState> emit) =>
      _refreshGroups(emit);
}
