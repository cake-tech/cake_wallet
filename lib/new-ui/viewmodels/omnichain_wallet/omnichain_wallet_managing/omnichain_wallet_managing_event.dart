import 'package:cw_core/wallet_info.dart';

sealed class OmniChainWalletManagingEvent {}

class OmniChainWalletManagingLoaded extends OmniChainWalletManagingEvent {}

class OmniChainWalletManagingSearchChanged extends OmniChainWalletManagingEvent {
  OmniChainWalletManagingSearchChanged(this.query);

  final String query;
}

class OmniChainWalletManagingCurrentWalletSelected extends OmniChainWalletManagingEvent {}

class OmniChainWalletManagingActivateSelectedWallet extends OmniChainWalletManagingEvent {
  OmniChainWalletManagingActivateSelectedWallet(this.walletInfo);

  final WalletInfo walletInfo;
}

class OmniChainWalletManagingWalletSelected extends OmniChainWalletManagingEvent {
  OmniChainWalletManagingWalletSelected(this.walletInfo);

  final WalletInfo walletInfo;
}
