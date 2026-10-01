import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/wallet_network.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/services/chain_list_service.dart";
import "package:cake_wallet/new-ui/services/evm_network_service.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:collection/collection.dart";
import "package:cw_core/evm_network.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/widgets.dart" show StringCharacters;

part "network_details_event.dart";
part "network_details_presentation.dart";
part "network_details_state.dart";

class NetworkDetailsBloc extends Bloc<NetworkDetailsEvent, NetworkDetailsState>
    with BlocPresentationMixin<NetworkDetailsState, NetworkDetailsPresentation> {
  NetworkDetailsBloc(
    this.network,
    this._networkService,
    this._chainListService,
    this._settingsStore,
  ) : super(NetworkDetailsState.initial(network)) {
    on<_Init>(_init);
    on<NetworkFieldChanged>(_onFieldChanged);
    on<FailoverUrlRevealed>(_onFailoverRevealed);
    on<ResetToDefaultRequested>(_onReset);
    on<NetworkSaveRequested>(_onSave, transformer: droppable());
    on<BorrowedTickerConfirmationAnswered>(_onBorrowedTickerAnswered, transformer: droppable());
    on<NetworkDeleteConfirmed>(_onDelete, transformer: droppable());

    add(const _Init());
  }

  final EvmNetwork? network;
  final EvmNetworkService _networkService;
  final ChainListService _chainListService;
  final SettingsStore _settingsStore;

  ChainListEntry? _defaultEntry;
  List<ChainListEntry> _chainListEntries = const [];
  List<EvmNetwork> _otherNetworks = const [];

  Future<void> _init(_Init event, Emitter<NetworkDetailsState> emit) async {
    final popular = await _chainListService.loadPopularNetworks();
    final cached = (await _chainListService.readCache())?.entries ?? const <ChainListEntry>[];
    _chainListEntries = [...popular, ...cached];
    _otherNetworks = (await EvmNetwork.getAll())
        .where((saved) => saved.chainId != this.network?.chainId)
        .toList();

    final network = this.network;
    if (network == null) {
      emit(state.copyWith(walletCount: 0, contactCount: 0));
      return;
    }

    if (!network.isManual) {
      _defaultEntry =
          _chainListEntries.firstWhereOrNull((entry) => entry.chainId == network.chainId);
    }

    final walletCount = await _networkService.walletCount(network.chainId);
    final currentNode = _settingsStore.evmChainNodes[network.chainId];

    final showsCurrentNode = walletCount > 0 && currentNode != null;
    final values = showsCurrentNode
        ? {...state.values, NetworkField.rpcUrl: currentNode.uri.toString()}
        : state.values;

    emit(
      state.copyWith(
        values: values,
        walletCount: walletCount,
        contactCount: _networkService.contactCount(network.chainId),
        canResetToDefault: _defaultEntry != null,
      ),
    );

    if (showsCurrentNode) {
      _present(NetworkDetailsFieldsFilled(values));
    }
  }

  void _onFieldChanged(NetworkFieldChanged event, Emitter<NetworkDetailsState> emit) {
    final value = event.field == NetworkField.symbol ? event.value.toUpperCase() : event.value;
    emit(
      state.copyWith(
        values: {...state.values, event.field: value},
        errors: {...state.errors}..remove(event.field),
      ),
    );
  }

  void _onFailoverRevealed(FailoverUrlRevealed event, Emitter<NetworkDetailsState> emit) =>
      emit(state.copyWith(isFailoverRevealed: true));

  void _onReset(ResetToDefaultRequested event, Emitter<NetworkDetailsState> emit) {
    final defaults = _defaultEntry;
    if (defaults == null) {
      return;
    }

    final rpcUrls = defaults.rpcUrls;
    final values = {...state.values, NetworkField.name: defaults.name};
    final errors = {...state.errors}..remove(NetworkField.name);
    values[NetworkField.explorerUrl] = defaults.explorerUrl ?? "";
    errors.remove(NetworkField.explorerUrl);

    if (!state.hasWallets) {
      values[NetworkField.rpcUrl] = rpcUrls.first;
      values[NetworkField.failoverUrl] = rpcUrls.length > 1 ? rpcUrls[1] : "";
      errors
        ..remove(NetworkField.rpcUrl)
        ..remove(NetworkField.failoverUrl);
    }

    emit(
      state.copyWith(
        values: values,
        errors: errors,
        isFailoverRevealed:
            state.isFailoverRevealed || (values[NetworkField.failoverUrl] ?? "").isNotEmpty,
      ),
    );
    emitPresentation(NetworkDetailsFieldsFilled(values));
  }

  Future<void> _onSave(NetworkSaveRequested event, Emitter<NetworkDetailsState> emit) async {
    if (!state.hasUsageCounts) {
      return;
    }

    final errors = _validate();
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors));
      return;
    }

    emit(state.copyWith(isSaving: true, errors: const {}));

    final symbol = state.value(NetworkField.symbol).trim();
    if (_borrowsMajorTicker(symbol)) {
      emitPresentation(
        BorrowedTickerConfirmationRequested(
          networkName: state.value(NetworkField.name).trim(),
          symbol: symbol,
        ),
      );
      return;
    }

    await _save(emit);
  }

  Future<void> _onBorrowedTickerAnswered(
    BorrowedTickerConfirmationAnswered event,
    Emitter<NetworkDetailsState> emit,
  ) async {
    if (!event.isConfirmed) {
      emit(state.copyWith(isSaving: false));
      return;
    }

    await _save(emit);
  }

  Future<void> _save(Emitter<NetworkDetailsState> emit) async {
    try {
      await _networkService.save(_networkFromForm(), previous: network);
      emit(state.copyWith(isSaving: false));
      _present(const NetworkDetailsSaved());
    } on RpcChainIdMismatchException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errors: {
            _fieldHoldingUrl(e.url): S.current.rpc_field_chain_id_mismatch(
              e.answeredChainId.toString(),
              e.expectedChainId.toString(),
            ),
          },
        ),
      );
    } on RpcNoAnswerException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errors: {_fieldHoldingUrl(e.url): S.current.rpc_field_no_answer},
        ),
      );
    } on NetworkInUseException catch (e) {
      final values = {...state.values, NetworkField.chainId: network!.chainId.toString()};
      emit(
        state.copyWith(
          isSaving: false,
          values: values,
          walletCount: e.walletCount,
          contactCount: e.contactCount,
        ),
      );
      _present(NetworkDetailsFieldsFilled(values));
    } catch (e) {
      printV("Failed to save network: $e");
      emit(state.copyWith(isSaving: false));
      _present(NetworkDetailsFailed(e.toString()));
    }
  }

  Future<void> _onDelete(NetworkDeleteConfirmed event, Emitter<NetworkDetailsState> emit) async {
    final network = this.network;
    if (network == null) {
      return;
    }

    try {
      await _networkService.delete(network);
      _present(const NetworkDetailsDeleted());
    } on NetworkInUseException catch (e) {
      emit(state.copyWith(walletCount: e.walletCount, contactCount: e.contactCount));
    } catch (e) {
      printV("Failed to delete network: $e");
      _present(NetworkDetailsFailed(e.toString()));
    }
  }

  bool _borrowsMajorTicker(String symbol) {
    if (state.mode == NetworkDetailsMode.chainList ||
        network?.symbol.toUpperCase() == symbol.toUpperCase()) {
      return false;
    }

    return EvmNetworkService.borrowsMajorTicker(symbol, isPopular: false, tvl: null);
  }

  void _present(NetworkDetailsPresentation event) {
    if (!isClosed) {
      emitPresentation(event);
    }
  }

  NetworkField _fieldHoldingUrl(String url) => url == state.value(NetworkField.rpcUrl).trim()
      ? NetworkField.rpcUrl
      : NetworkField.failoverUrl;

  EvmNetwork _networkFromForm() {
    final original = network;
    final name = state.value(NetworkField.name).trim();
    final isChainList = state.mode == NetworkDetailsMode.chainList;

    return EvmNetwork(
      chainId: tryParseChainId(state.value(NetworkField.chainId))!,
      name: name,
      symbol: state.value(NetworkField.symbol).trim(),
      decimals: original?.decimals ?? 18,
      tag: isChainList ? original!.tag : EvmNetworkService.tagFor(name),
      rpcUrl: state.hasWallets ? original!.rpcUrl : state.value(NetworkField.rpcUrl).trim(),
      failoverUrl:
          state.hasWallets ? original!.failoverUrl : _valueOrNull(NetworkField.failoverUrl),
      explorerUrl: _valueOrNull(NetworkField.explorerUrl),
      iconUrl: isChainList ? original!.iconUrl : _valueOrNull(NetworkField.iconUrl),
      isManual: !isChainList,
      isEnabled: original?.isEnabled ?? true,
      enabledAt: original?.enabledAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  String? _valueOrNull(NetworkField field) {
    final value = state.value(field).trim();
    return value.isEmpty ? null : value;
  }

  Map<NetworkField, String> _validate() {
    final errors = <NetworkField, String>{};
    final name = state.value(NetworkField.name).trim();
    final lowered = name.toLowerCase();
    final builtinNames = [
      ...builtinNetworkTypes.map(walletTypeToDisplayName),
      ..._settingsStore.evmNetworks.values
          .where((chain) => chain.source == ChainSource.builtin)
          .map((chain) => chain.name),
    ];
    final addedNames = _otherNetworks.map((other) => other.name);

    if (name.isEmpty) {
      errors[NetworkField.name] = S.current.field_required;
    } else if (name.characters.length > maxNetworkNameLength) {
      errors[NetworkField.name] = S.current.network_name_too_long;
    } else if ([...builtinNames, ...addedNames].any((other) => other.toLowerCase() == lowered)) {
      errors[NetworkField.name] = S.current.network_name_exists(name);
    }

    if (!state.isReadOnly(NetworkField.rpcUrl)) {
      final rpcUrl = state.value(NetworkField.rpcUrl).trim();
      final failoverUrl = state.value(NetworkField.failoverUrl).trim();

      if (rpcUrl.isEmpty) {
        errors[NetworkField.rpcUrl] = S.current.field_required;
      } else if (!_isHttps(rpcUrl)) {
        errors[NetworkField.rpcUrl] = S.current.url_must_be_https;
      }

      if (failoverUrl.isNotEmpty && !_isHttps(failoverUrl)) {
        errors[NetworkField.failoverUrl] = S.current.url_must_be_https;
      } else if (failoverUrl.isNotEmpty && failoverUrl == rpcUrl) {
        errors[NetworkField.failoverUrl] = S.current.failover_must_differ;
      }
    }

    if (!state.isReadOnly(NetworkField.chainId)) {
      final chainIdError = _chainIdError();
      if (chainIdError != null) {
        errors[NetworkField.chainId] = chainIdError;
      }
    }

    if (!state.isReadOnly(NetworkField.symbol)) {
      final symbol = state.value(NetworkField.symbol).trim();
      if (symbol.isEmpty) {
        errors[NetworkField.symbol] = S.current.field_required;
      } else if (!RegExp(r"^[A-Z0-9]{1,10}$").hasMatch(symbol)) {
        errors[NetworkField.symbol] = S.current.symbol_format;
      }
    }

    final explorerUrl = state.value(NetworkField.explorerUrl).trim();
    if (explorerUrl.isNotEmpty && !_isHttps(explorerUrl)) {
      errors[NetworkField.explorerUrl] = S.current.url_must_be_https;
    }

    final iconUrlError = iconUrlErrorFor(state.mode, state.value(NetworkField.iconUrl));
    if (iconUrlError != null) {
      errors[NetworkField.iconUrl] = iconUrlError;
    }

    return errors;
  }

  static String? iconUrlErrorFor(NetworkDetailsMode mode, String iconUrl) {
    final value = iconUrl.trim();
    if (mode == NetworkDetailsMode.chainList || value.isEmpty) {
      return null;
    }

    return _isHttps(value) ? null : S.current.url_must_be_https;
  }

  String? _chainIdError() {
    final input = state.value(NetworkField.chainId).trim();
    if (input.isEmpty) {
      return S.current.field_required;
    }

    final chainId = tryParseChainId(input);
    if (chainId == null) {
      return S.current.chain_id_whole_number;
    }

    final chainIdText = chainId.toString();
    final registeredChain = _settingsStore.evmNetworks[chainId];
    if (registeredChain != null && registeredChain.source == ChainSource.builtin) {
      return S.current.chain_id_used_by_builtin(chainIdText, registeredChain.name);
    }

    final other = _otherNetworks.firstWhereOrNull((other) => other.chainId == chainId);
    if (other != null) {
      return S.current.chain_id_used_by_network(chainIdText, other.name);
    }

    final chainListEntry = state.mode == NetworkDetailsMode.manualAdd
        ? _chainListEntries.firstWhereOrNull((entry) => entry.chainId == chainId)
        : null;
    if (chainListEntry != null) {
      return S.current.chain_id_listed_on_chainlist(chainIdText, chainListEntry.name);
    }

    return null;
  }

  static bool _isHttps(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == "https" && uri.host.isNotEmpty;
  }

  static int? tryParseChainId(String input) {
    final normalized = input.trim().toLowerCase();
    final chainId = normalized.startsWith("0x")
        ? int.tryParse(normalized.substring(2), radix: 16)
        : int.tryParse(normalized);
    return chainId != null && chainId > 0 ? chainId : null;
  }
}
