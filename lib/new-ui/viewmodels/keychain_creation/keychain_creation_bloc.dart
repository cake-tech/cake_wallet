import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_creation/keychain_creation_presentation_event.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/wallet_type.dart";
import "package:cw_keychain/cw_keychain.dart";
import "package:meta/meta.dart";

part "keychain_creation_event.dart";

part "keychain_creation_state.dart";

class KeychainCreationBloc extends Bloc<KeychainCreationEvent, KeychainCreationState> with BlocPresentationMixin<KeychainCreationState, KeychainCreationPresentationEvent> {

  KeychainCreationBloc({required CwKeychain keychain, required AppStore appStore})
      : _keychain = keychain,
        _appStore = appStore,
        super(const KeychainCreationNotLoaded()) {
    on<_Init>(_init);
    on<KeychainModeChanged>(_onKeychainModeChanged, transformer: restartable());
    on<KeychainModeAccepted>(_onKeychainModeAccepted, transformer: droppable());
    add(const _Init());
  }
  final AppStore _appStore;
  final CwKeychain _keychain;

  WalletType get walletType => _appStore.wallet!.type;

  Future<void> _init(_Init evnet, Emitter<KeychainCreationState> emit,) async {
      if(await _keychain.available()) {
        emit(const KeychainStateInput(useKeychain: true));
      } else {
        // keychain unavailable, we say it's complete so ui goes straight to seed page
        emit(const KeychainStateComplete(redirectToSeed: true));
      }
  }

  Future<void> _onKeychainModeChanged(
      KeychainModeChanged event, Emitter<KeychainCreationState> emit,) async {
    emit(KeychainStateInput(useKeychain: event.useKeychain));
  }

  Future<void> _onKeychainModeAccepted(
      KeychainModeAccepted event, Emitter<KeychainCreationState> emit,) async {
    if (state case final KeychainStateInput s) {
      emit(KeychainStateSaving(useKeychain: s.useKeychain));
      if (s.useKeychain) {
        try {
          await _keychain.put(KeychainData(
            name: _appStore.wallet!.name,
            walletTypeRaw: serializeToInt(_appStore.wallet!.type),
            seed: _appStore.wallet!.seed!,
            passphrase: _appStore.wallet!.passphrase,
            seedTypeRaw: seedTypeRaw,
            blockHeight: await restoreHeight,
          ),);
        } catch(e) {
          emitPresentation(KeychainSaveFailed(error: e));
          return;
        }
      }
      emit(KeychainStateComplete(redirectToSeed: !s.useKeychain));
    }
  }

  int? get seedTypeRaw => switch (_appStore.wallet!.type) {
        WalletType.monero => _appStore.settingsStore.moneroSeedType.raw,
        WalletType.bitcoin => _appStore.settingsStore.bitcoinSeedType.raw,
        WalletType.nano => _appStore.settingsStore.nanoSeedType.raw,
        _ => null
      };


  Future<int?> get restoreHeight async {
    if (_appStore.wallet!.type == WalletType.monero) {
      return monero!.getRestoreHeight(_appStore.wallet!);
    }
    if (_appStore.wallet!.type == WalletType.zcash) {
      return int.tryParse(zcash!.getKeys(_appStore.wallet!)["restoreHeight"]?.toString() ?? "");
    }
    return null;
  }
}
