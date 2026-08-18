part of 'keychain_management_bloc.dart';

@immutable
sealed class KeychainManagementEvent {
  const KeychainManagementEvent();
}

final class _Init extends KeychainManagementEvent {
  const _Init();
}

final class ItemUnsaved extends KeychainManagementEvent {
  const ItemUnsaved(this.index);

  final int index;
}

final class ItemSaved extends KeychainManagementEvent {
  const ItemSaved(this.index);

  final int index;
}

final class KeychainCleared extends KeychainManagementEvent {
  const KeychainCleared();
}
