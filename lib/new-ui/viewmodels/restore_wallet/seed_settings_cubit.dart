import "package:cake_wallet/entities/seed_type.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/seed_settings_store.dart";
import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:mobx/mobx.dart";

part "seed_settings_state.dart";

class SeedSettingsCubit extends Cubit<SeedSettingsState> {
  SeedSettingsCubit(this._appStore, this._seedSettingsStore)
      : super(
          SeedSettingsState(
            moneroSeedType: _appStore.settingsStore.moneroSeedType,
            bitcoinSeedType: _appStore.settingsStore.bitcoinSeedType,
            nanoSeedType: _appStore.settingsStore.nanoSeedType,
            passphrase: _seedSettingsStore.passphrase,
          ),
        ) {
    final settingsStore = _appStore.settingsStore;
    _storeReactionDisposers = [
      reaction<MoneroSeedType>(
        (_) => settingsStore.moneroSeedType,
        (seedType) => _emitIfOpen(state.copyWith(moneroSeedType: seedType)),
      ),
      reaction<BitcoinSeedType>(
        (_) => settingsStore.bitcoinSeedType,
        (seedType) => _emitIfOpen(state.copyWith(bitcoinSeedType: seedType)),
      ),
      reaction<NanoSeedType>(
        (_) => settingsStore.nanoSeedType,
        (seedType) => _emitIfOpen(state.copyWith(nanoSeedType: seedType)),
      ),
      reaction<String?>(
        (_) => _seedSettingsStore.passphrase,
        (passphrase) => _emitIfOpen(state.copyWith(passphrase: () => passphrase)),
      ),
    ];
  }

  final AppStore _appStore;
  final SeedSettingsStore _seedSettingsStore;
  late final List<ReactionDisposer> _storeReactionDisposers;

  void setMoneroSeedType(MoneroSeedType seedType) {
    _appStore.settingsStore.moneroSeedType = seedType;
    _emitIfOpen(state.copyWith(moneroSeedType: seedType));
  }

  void setBitcoinSeedType(BitcoinSeedType seedType) {
    _appStore.settingsStore.bitcoinSeedType = seedType;
    _emitIfOpen(state.copyWith(bitcoinSeedType: seedType));
  }

  void setNanoSeedType(NanoSeedType seedType) {
    _appStore.settingsStore.nanoSeedType = seedType;
    _emitIfOpen(state.copyWith(nanoSeedType: seedType));
  }

  void setPassphrase(String? passphrase) {
    _seedSettingsStore.passphrase = passphrase;
    _emitIfOpen(state.copyWith(passphrase: () => passphrase));
  }

  void _emitIfOpen(SeedSettingsState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  @override
  Future<void> close() {
    for (final dispose in _storeReactionDisposers) {
      dispose();
    }
    return super.close();
  }
}
