import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";

sealed class WalletEditEvent {}

class WalletEditStarted extends WalletEditEvent {
  WalletEditStarted(this.groupKey);

  final String groupKey;
}

class WalletEditNameChanged extends WalletEditEvent {
  WalletEditNameChanged(this.name);

  final String name;
}

class WalletEditRenameSubmitted extends WalletEditEvent {}

class WalletEditIconChanged extends WalletEditEvent {
  WalletEditIconChanged(this.icon);

  final WalletIcon icon;
}