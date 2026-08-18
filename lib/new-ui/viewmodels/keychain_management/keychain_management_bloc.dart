import "package:bloc/bloc.dart";
import "package:cake_wallet/core/wallet_loading_service.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:cw_keychain/cw_keychain.dart";
import "package:meta/meta.dart";

part "keychain_management_event.dart";
part "keychain_management_state.dart";

class KeychainManagementBloc extends Bloc<KeychainManagementEvent, KeychainManagementState> {
  KeychainManagementBloc({required SettingsStore settingsStore, required WalletLoadingService walletLoadingService, required CwKeychain keychain}) : _settingsStore = settingsStore, _walletLoadingService = walletLoadingService, _keychain = keychain, super(const KeychainManagementNotLoaded()) {
    on<_Init>(_init);
    on<ItemSaved>(_onItemSaved);
    on<ItemUnsaved>(_onItemUnsaved);
    add(const _Init());
  }

  final CwKeychain _keychain;
  final WalletLoadingService _walletLoadingService;
  final SettingsStore _settingsStore;

  Future<void> _init(_Init event, Emitter<KeychainManagementState> emit) async {
    if(!(await _keychain.available())) {
      emit(const KeychainManagementUnavailable());
      return;
    }

    emit(KeychainManagementLoaded(
        localWallets: await WalletInfo.getAll(),
        keychainWallets: await _keychain.getAll(),
        unsupportedKeychainItems: await _keychain.getUnsupported()));
  }

  Future<void> _onItemSaved(ItemSaved event, Emitter<KeychainManagementState> emit) async {
    if(state case final KeychainManagementLoaded s) {
        final wi = s.savableWallets[event.index];
        final wallet = await _walletLoadingService.load(wi.type, wi.name);
        final derivationInfo = await wi.getDerivationInfo();

        await _keychain.put(KeychainDataV1(
          name: wallet.name,
          walletTypeRaw: serializeToInt(wallet.type),
          // we only support mainnet and testnet right now
          networkRaw: wallet.isTestnet ? 1 : 0,
          // "1" is "default"
          derivationTypeRaw: derivationInfo.derivationType?.index ?? 1,
          derivationPath: derivationInfo.derivationPath,
          seed: wallet.seed!,
          passphrase: wallet.passphrase,
          seedTypeRaw: seedTypeRaw(wallet.type),
          blockHeight: await restoreHeight(wallet),
          creationTime: DateTime.now().millisecondsSinceEpoch,
        ),);

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

  int? seedTypeRaw(WalletType type) => switch (type) {
    WalletType.monero => _settingsStore.moneroSeedType.raw,
    WalletType.bitcoin => _settingsStore.bitcoinSeedType.raw,
    WalletType.nano => _settingsStore.nanoSeedType.raw,
    _ => null
  };



  Future<int?> restoreHeight(WalletBase wallet) async {
    if (wallet.type == WalletType.monero) {
      return monero!.getRestoreHeight(wallet);
    }
    if (wallet.type == WalletType.zcash) {
      return int.tryParse(zcash!.getKeys(wallet)["restoreHeight"]?.toString() ?? "");
    }
    return null;
  }
}
