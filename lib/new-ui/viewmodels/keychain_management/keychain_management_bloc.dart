import "package:bloc/bloc.dart";
import "package:cake_wallet/core/wallet_loading_service.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_creation/keychain_wallet_extension.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_keychain/cw_keychain.dart";
import "package:meta/meta.dart";

part "keychain_management_event.dart";

part "keychain_management_state.dart";

class KeychainManagementBloc extends Bloc<KeychainManagementEvent, KeychainManagementState> {
  KeychainManagementBloc(
      {required WalletLoadingService walletLoadingService, required CwKeychain keychain})
      : _walletLoadingService = walletLoadingService,
        _keychain = keychain,
        super(const KeychainManagementNotLoaded()) {
    on<_Init>(_init);
    on<ItemSaved>(_onItemSaved);
    on<ItemUnsaved>(_onItemUnsaved);
    on<KeychainCleared>(_onKeychainCleared);
    add(const _Init());
  }

  final CwKeychain _keychain;
  final WalletLoadingService _walletLoadingService;

  Future<void> _init(_Init event, Emitter<KeychainManagementState> emit) async {
    if (!(await _keychain.available())) {
      emit(const KeychainManagementUnavailable());
      return;
    }

    emit(KeychainManagementLoaded(
        localWallets: await WalletInfo.getAll(),
        keychainWallets: await _keychain.getAll(),
        unsupportedKeychainItems: await _keychain.getUnsupported()));
  }

  Future<void> _onItemSaved(ItemSaved event, Emitter<KeychainManagementState> emit) async {
    if (state case final KeychainManagementLoaded s) {
      final wi = s.savableWallets[event.index];
      final wallet = await _walletLoadingService.load(wi.type, wi.name);
      await _keychain.put(wallet.keychainData);

      emit(s.copyWith(keychainWallets: await _keychain.getAll()));
    }
  }

  Future<void> _onItemUnsaved(ItemUnsaved event, Emitter<KeychainManagementState> emit) async {
    if (state case final KeychainManagementLoaded s) {
      final item = s.keychainWallets[event.index];
      final id = "${item.name}_${item.walletTypeRaw}";
      await _keychain.delete(id);
      emit(s.copyWith(keychainWallets: await _keychain.getAll()));
    }
  }

  Future<void> _onKeychainCleared(
      KeychainCleared event, Emitter<KeychainManagementState> emit,) async {
    if (state case final KeychainManagementLoaded s) {
      final ids = [
        ...s.keychainWallets.map((item) => "${item.name}_${item.walletTypeRaw}"),
        ...s.unsupportedKeychainItems.map((item) => "${item.name}_${item.walletTypeRaw}"),
      ];

      for (final id in ids) {
        await _keychain.delete(id);
      }

      emit(s.copyWith(
        keychainWallets: await _keychain.getAll(),
        unsupportedKeychainItems: await _keychain.getUnsupported(),
      ),);
    }
  }
}
