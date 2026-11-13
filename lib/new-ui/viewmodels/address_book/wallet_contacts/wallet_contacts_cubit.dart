import "dart:async";

import "package:bloc/bloc.dart";
import "package:cake_wallet/core/services/wallet_group_service.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_contact_utils.dart";
import "package:cake_wallet/entities/wallet_group.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_contact_entry.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_contact_loader.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_state.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:mobx/mobx.dart";

typedef WalletContactEntriesLoader = Future<List<WalletContactEntry>> Function(WalletInfo info);


class WalletContactsCubit extends Cubit<WalletContactsState> {
  WalletContactsCubit({
    required this.groupService,
    required this.appStore,
    this.currencyFilter,
    this.chainIdForWalletType,
    WalletContactEntriesLoader? loadEntries,
  })  : _loadEntries = loadEntries ?? loadWalletContactEntries,
        super(const WalletContactsState());

  final WalletGroupService groupService;
  final AppStore appStore;

  /// Picker mode: only contacts valid for this currency are kept.
  final CryptoCurrency? currencyFilter;

  /// Resolves EVM chain ids for the currency filter; null disables the chain-id check.
  final ChainIdForWalletType? chainIdForWalletType;

  final WalletContactEntriesLoader _loadEntries;

  /// Per wallet id; futures so concurrent rebuilds share one read.
  final Map<String, Future<List<WalletContactEntry>>> _entries = {};

  /// Bumped by every rebuild; a rebuild only emits if no newer one started meanwhile.
  int _generation = 0;

  StreamSubscription<List<WalletGroup>>? _groupsSubscription;
  ReactionDisposer? _walletReaction;

  bool get isPicker => currencyFilter != null;

  /// Reads every wallet's addresses, emits the groups and starts following group changes
  /// and wallet switches. Safe to call more than once.
  Future<void> load() async {
    // watch() replays the current list; it's built right below, so skip the replay.
    _groupsSubscription ??= groupService.watch().skip(1).listen((groups) => _rebuild(groups));
    _walletReaction ??= reaction((_) => appStore.wallet, (_) => _rebuild(groupService.groups));

    _entries.clear();
    if (groupService.groups.isEmpty) await groupService.updateWalletGroups();
    if (isClosed) return;
    await _rebuild(groupService.groups);
  }

  /// Re-reads the groups and every wallet's addresses (e.g. new receive addresses).
  Future<void> refresh() async {
    _entries.clear();
    await groupService.updateWalletGroups();
    if (isClosed) return;
    await _rebuild(groupService.groups);
  }

  Future<void> _rebuild(List<WalletGroup> groups) async {
    final generation = ++_generation;
    if (isClosed) return;
    if (state.status == WalletContactsStatus.initial) {
      emit(state.copyWith(status: WalletContactsStatus.loading));
    }

    try {
      final wallets = [
        for (final group in groups)
          for (final wallet in group.wallets)
            if (wallet.isReady) wallet,
      ];
      final ids = wallets.map((w) => w.id).toSet();
      _entries.removeWhere((id, _) => !ids.contains(id));

      final entriesByWalletId = <String, List<WalletContactEntry>>{};
      for (final wallet in wallets) {
        entriesByWalletId[wallet.id] = await _entriesFor(wallet);
      }
      if (isClosed || generation != _generation) return;

      final currentGroupId = _currentGroupId();
      emit(WalletContactsState(
        status: WalletContactsStatus.loaded,
        currentGroupId: currentGroupId,
        groups: buildWalletContactGroups(
          groups: groups,
          entriesByWalletId: entriesByWalletId,
          currentGroupId: currentGroupId,
          currency: currencyFilter,
          chainIdForWalletType: chainIdForWalletType,
        ),
      ));
    } catch (e, s) {
      if (isClosed || generation != _generation) return;
      printV("WalletContactsCubit: rebuild failed: $e\n$s");
      emit(state.copyWith(status: WalletContactsStatus.failure, error: e));
    }
  }

  Future<List<WalletContactEntry>> _entriesFor(WalletInfo wallet) =>
      _entries.putIfAbsent(wallet.id, () async {
        try {
          return await _loadEntries(wallet);
        } catch (e) {
          // Not cached: the next rebuild tries again.
          printV("WalletContactsCubit: loading addresses failed: $e");
          _entries.remove(wallet.id);
          return const [];
        }
      });

  String? _currentGroupId() {
    final info = appStore.wallet?.walletInfo;
    return info == null ? null : groupService.resolveGroupKey(info);
  }

  @override
  Future<void> close() async {
    await _groupsSubscription?.cancel();
    _groupsSubscription = null;
    _walletReaction?.call();
    _walletReaction = null;
    return super.close();
  }
}
