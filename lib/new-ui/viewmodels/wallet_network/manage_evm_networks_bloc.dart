import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/new-ui/services/chain_list_service.dart";
import "package:cake_wallet/new-ui/services/evm_network_service.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/evm_network.dart";
import "package:cw_core/utils/print_verbose.dart";

part "manage_evm_networks_event.dart";
part "manage_evm_networks_presentation.dart";
part "manage_evm_networks_state.dart";

class ManageEvmNetworksBloc extends Bloc<ManageEvmNetworksEvent, ManageEvmNetworksState>
    with BlocPresentationMixin<ManageEvmNetworksState, ManageEvmNetworksPresentation> {
  ManageEvmNetworksBloc(this._networkService, this._chainListService, this._settingsStore)
      : super(
          const ManageEvmNetworksState(
            manualNetworks: [],
            popularNetworks: [],
            alphabeticalNetworks: [],
            chainListStatus: ChainListFetching(),
            query: "",
            togglingChainIds: {},
          ),
        ) {
    on<_Init>(_init, transformer: restartable());
    on<ChainListRetryRequested>(_onRetry, transformer: droppable());
    on<ManageEvmNetworksSearchChanged>(_onSearchChanged);
    on<NetworkToggleRequested>(_onToggleRequested);
    on<BorrowedTickerConfirmationAnswered>(_onBorrowedTickerAnswered);
    on<_NetworkToggled>(_onToggle, transformer: sequential());
    on<NetworksChanged>(_onNetworksChanged, transformer: sequential());

    add(const _Init());
  }

  final EvmNetworkService _networkService;
  final ChainListService _chainListService;
  final SettingsStore _settingsStore;

  Map<int, ChainListEntry> _popularEntries = const {};
  Map<int, ChainListEntry> _chainListEntries = const {};
  List<EvmNetwork> _chainListNetworks = const [];
  List<EvmNetwork> _savedNetworks = const [];

  Future<void> _init(
    _Init event,
    Emitter<ManageEvmNetworksState> emit,
  ) async {
    _popularEntries = {
      for (final entry in await _chainListService.loadPopularNetworks()) entry.chainId: entry,
    };
    _savedNetworks = await EvmNetwork.getAll();
    final cache = await _chainListService.readCache();
    _setChainListEntries(cache?.entries ?? const []);

    emit(_rebuiltState());

    await _fetchChainList(emit, savedCopyDate: cache?.fetchedAt);
  }

  Future<void> _onRetry(ChainListRetryRequested event, Emitter<ManageEvmNetworksState> emit) async {
    emit(state.copyWith(chainListStatus: const ChainListFetching()));

    await _fetchChainList(emit, savedCopyDate: null);
  }

  Future<void> _fetchChainList(
    Emitter<ManageEvmNetworksState> emit, {
    required DateTime? savedCopyDate,
  }) async {
    try {
      _setChainListEntries((await _chainListService.fetch()).entries);
      emit(_rebuiltState(chainListStatus: const ChainListLoaded()));
    } catch (e) {
      printV("ChainList fetch failed: $e");

      emit(
        _rebuiltState(
          chainListStatus: savedCopyDate != null
              ? ChainListSavedCopy(savedCopyDate)
              : const ChainListFetchFailed(),
        ),
      );
    }
  }

  void _onSearchChanged(
    ManageEvmNetworksSearchChanged event,
    Emitter<ManageEvmNetworksState> emit,
  ) =>
      emit(state.copyWith(query: event.query));

  Future<void> _onNetworksChanged(
    NetworksChanged event,
    Emitter<ManageEvmNetworksState> emit,
  ) async {
    _savedNetworks = await EvmNetwork.getAll();
    emit(_rebuiltState());
  }

  void _onToggleRequested(
    NetworkToggleRequested event,
    Emitter<ManageEvmNetworksState> emit,
  ) {
    final network = event.network;
    if (state.togglingChainIds.contains(network.chainId)) {
      return;
    }

    emit(state.copyWith(togglingChainIds: {...state.togglingChainIds, network.chainId}));

    if (event.shouldEnable && _borrowsKnownTicker(network)) {
      emitPresentation(BorrowedTickerConfirmationRequested(network));
      return;
    }

    add(_NetworkToggled(network, shouldEnable: event.shouldEnable));
  }

  void _onBorrowedTickerAnswered(
    BorrowedTickerConfirmationAnswered event,
    Emitter<ManageEvmNetworksState> emit,
  ) {
    final network = event.network;
    if (event.isConfirmed) {
      add(_NetworkToggled(network, shouldEnable: true));
      return;
    }

    emit(state.copyWith(togglingChainIds: {...state.togglingChainIds}..remove(network.chainId)));
  }

  Future<void> _onToggle(_NetworkToggled event, Emitter<ManageEvmNetworksState> emit) async {
    final network = event.network;

    try {
      if (event.shouldEnable) {
        await _networkService.enable(network, rpcCandidates: _rpcCandidates(network));
      } else {
        await _networkService.disable(network);
      }
      _savedNetworks = await EvmNetwork.getAll();
    } on RpcChainIdMismatchException catch (e) {
      _present(
        RpcChainIdMismatchRefused(
          networkName: network.name,
          answeredChainId: e.answeredChainId,
          expectedChainId: e.expectedChainId,
        ),
      );
    } on RpcNoAnswerException {
      _present(RpcNoAnswerRefused(network.name));
    } on NetworkInUseException catch (e) {
      _present(NetworkInUseRefused(networkName: network.name, walletCount: e.walletCount));
    } catch (e) {
      printV("Failed to toggle network ${network.chainId}: $e");
      _present(NetworkToggleFailed(e.toString()));
    }

    emit(_rebuiltState(togglingChainIds: {...state.togglingChainIds}..remove(network.chainId)));
  }

  void _present(ManageEvmNetworksPresentation event) {
    if (!isClosed) {
      emitPresentation(event);
    }
  }

  void _setChainListEntries(List<ChainListEntry> entries) {
    _chainListEntries = {for (final entry in entries) entry.chainId: entry};
    _chainListNetworks = _chainListEntries.values.map(_networkService.networkFromEntry).toList();
  }

  ManageEvmNetworksState _rebuiltState({
    ChainListStatus? chainListStatus,
    Set<int>? togglingChainIds,
  }) =>
      state.copyWith(
        manualNetworks: _manualNetworks(),
        popularNetworks: _popularNetworks(),
        alphabeticalNetworks: _alphabeticalNetworks(),
        chainListStatus: chainListStatus,
        togglingChainIds: togglingChainIds,
      );

  List<EvmNetwork> _manualNetworks() =>
      _savedNetworks.where((network) => network.isManual).toList();

  List<EvmNetwork> _popularNetworks() {
    final savedByChainId = {for (final network in _savedNetworks) network.chainId: network};

    return _popularEntries.values
        .where(
          (entry) =>
              !_isBuiltinChain(entry.chainId) && savedByChainId[entry.chainId]?.isManual != true,
        )
        .map((entry) => savedByChainId[entry.chainId] ?? _networkService.networkFromEntry(entry))
        .toList();
  }

  List<EvmNetwork> _alphabeticalNetworks() {
    if (_chainListEntries.isEmpty) {
      return const [];
    }

    final savedIds = _savedNetworks.map((network) => network.chainId).toSet();
    final networks = [
      for (final network in _chainListNetworks)
        if (!_popularEntries.containsKey(network.chainId) &&
            !savedIds.contains(network.chainId) &&
            !_isBuiltinChain(network.chainId))
          network,
      for (final network in _savedNetworks)
        if (!network.isManual && !_popularEntries.containsKey(network.chainId)) network,
    ];

    return networks..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<String> _rpcCandidates(EvmNetwork network) {
    if (network.isManual) {
      return const [];
    }

    final entry = _popularEntries[network.chainId] ?? _chainListEntries[network.chainId];
    if (entry == null) {
      return const [];
    }

    final rpcUrls = entry.rpcUrls;
    final failoverUrl = network.failoverUrl;
    if (!rpcUrls.contains(network.rpcUrl) ||
        (failoverUrl != null && !rpcUrls.contains(failoverUrl))) {
      return const [];
    }

    return [
      network.rpcUrl,
      if (failoverUrl != null) failoverUrl,
      ...rpcUrls.where((url) => url != network.rpcUrl && url != failoverUrl),
    ];
  }

  bool _borrowsKnownTicker(EvmNetwork network) {
    final isPopular = _popularEntries.containsKey(network.chainId);
    final tvl = _chainListEntries[network.chainId]?.tvl;
    if (network.isManual || isPopular || (tvl != null && tvl > 0)) {
      return false;
    }

    return EvmNetworkService.borrowsKnownTicker(
      network.symbol,
      popularEntries: _popularEntries.values,
    );
  }

  bool _isBuiltinChain(int chainId) =>
      _settingsStore.evmNetworks[chainId]?.source == ChainSource.builtin;
}
