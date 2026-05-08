import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

const Object _noChange = Object();

class OmniChainWalletManagingState {
  OmniChainWalletManagingState({
    this.currentNetwork,
    this.wallets = const [],
    this.filteredWallets = const [],
    this.selectedWallet,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final WalletType? currentNetwork;
  final List<WalletInfo> wallets;
  final List<WalletInfo> filteredWallets;
  final WalletInfo? selectedWallet;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  OmniChainWalletManagingState copyWith({
    WalletType? currentNetwork,
    List<WalletInfo>? wallets,
    List<WalletInfo>? filteredWallets,
    Object? selectedWallet = _noChange,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return OmniChainWalletManagingState(
      currentNetwork: currentNetwork ?? this.currentNetwork,
      wallets: wallets ?? this.wallets,
      filteredWallets: filteredWallets ?? this.filteredWallets,
      selectedWallet: selectedWallet == _noChange ? this.selectedWallet : selectedWallet as WalletInfo?,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
