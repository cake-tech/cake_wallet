import 'package:bloc/bloc.dart';
import 'package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_service.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/managing/omnichain_wallet_managing_event.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/managing/omnichain_wallet_managing_state.dart';

import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

class OmniChainWalletManagingBloc
    extends Bloc<OmniChainWalletManagingEvent, OmniChainWalletManagingState> {
  OmniChainWalletManagingBloc({
    required this.omniChainWalletCreationService,
  }) : super(OmniChainWalletManagingState()) {
    on<OmniChainWalletManagingLoaded>(_onLoaded);
    on<OmniChainWalletManagingSearchChanged>(_onSearchChanged);
    on<OmniChainWalletManagingCurrentWalletSelected>(_onCurrentWalletSelected);
    on<OmniChainWalletManagingWalletSelected>(_onWalletSelected);
    on<OmniChainWalletManagingActivateSelectedWallet>(_onActivateSelectedWallet);
    on<OmniChainWalletManagingNetworksAdded>(_onNetworksAdded);
  }

  final OmniChainWalletCreationService omniChainWalletCreationService;

  Future<void> _onLoaded(
    OmniChainWalletManagingLoaded event,
    Emitter<OmniChainWalletManagingState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final currentNetwork = omniChainWalletCreationService.appStore.wallet?.type;
      final wallets = await omniChainWalletCreationService.getCurrentWalletGroupWallets();
      final otherWallets =
          wallets.where((walletInfo) => walletInfo.type != currentNetwork).toList();

      emit(state.copyWith(
        currentNetwork: currentNetwork,
        wallets: otherWallets,
        filteredWallets: _filterWallets(otherWallets, state.searchQuery),
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void _onSearchChanged(
    OmniChainWalletManagingSearchChanged event,
    Emitter<OmniChainWalletManagingState> emit,
  ) {
    emit(state.copyWith(
      searchQuery: event.query,
      filteredWallets: _filterWallets(state.wallets, event.query),
    ));
  }

  void _onCurrentWalletSelected(
    OmniChainWalletManagingCurrentWalletSelected event,
    Emitter<OmniChainWalletManagingState> emit,
  ) {
    emit(state.copyWith(selectedWallet: null));
  }

  void _onWalletSelected(
    OmniChainWalletManagingWalletSelected event,
    Emitter<OmniChainWalletManagingState> emit,
  ) {
    emit(state.copyWith(selectedWallet: event.walletInfo));
  }

  Future<void> _onActivateSelectedWallet(
      OmniChainWalletManagingActivateSelectedWallet event,
      Emitter<OmniChainWalletManagingState> emit,
      ) async {
    if (event.walletInfo.type == state.currentNetwork) return;

    emit(state.copyWith(selectedWallet: event.walletInfo, isLoading: true, error: null));

    try {
      await omniChainWalletCreationService.activatePlaceholderWallet(event.walletInfo);
      emit(state.copyWith(isLoading: false, closeRequested: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onNetworksAdded(
    OmniChainWalletManagingNetworksAdded event,
    Emitter<OmniChainWalletManagingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await omniChainWalletCreationService.addNetworksToCurrentGroup(event.types);
      add(OmniChainWalletManagingLoaded());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<WalletInfo> _filterWallets(List<WalletInfo> wallets, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return wallets;

    return wallets
        .where((walletInfo) =>
            walletTypeToDisplayName(walletInfo.type).toLowerCase().contains(normalizedQuery))
        .toList();
  }
}
