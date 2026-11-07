import "package:cake_wallet/entities/seed_type.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/authentication_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:mobx/mobx.dart" as mobx;
import "package:mocktail/mocktail.dart";

class FakeSettingsStore extends Fake implements SettingsStore {
  FakeSettingsStore({
    MoneroSeedType moneroSeedType = MoneroSeedType.legacy,
    BitcoinSeedType bitcoinSeedType = BitcoinSeedType.electrum,
    NanoSeedType nanoSeedType = NanoSeedType.nanoStandard,
  })  : _moneroSeedType = mobx.Observable(moneroSeedType),
        _bitcoinSeedType = mobx.Observable(bitcoinSeedType),
        _nanoSeedType = mobx.Observable(nanoSeedType);

  final mobx.Observable<MoneroSeedType> _moneroSeedType;
  final mobx.Observable<BitcoinSeedType> _bitcoinSeedType;
  final mobx.Observable<NanoSeedType> _nanoSeedType;

  @override
  MoneroSeedType get moneroSeedType => _moneroSeedType.value;

  @override
  set moneroSeedType(MoneroSeedType value) => mobx.runInAction(() => _moneroSeedType.value = value);

  @override
  BitcoinSeedType get bitcoinSeedType => _bitcoinSeedType.value;

  @override
  set bitcoinSeedType(BitcoinSeedType value) =>
      mobx.runInAction(() => _bitcoinSeedType.value = value);

  @override
  NanoSeedType get nanoSeedType => _nanoSeedType.value;

  @override
  set nanoSeedType(NanoSeedType value) => mobx.runInAction(() => _nanoSeedType.value = value);
}

class MockAppStore extends Mock implements AppStore {}

class MockAuthenticationStore extends Mock implements AuthenticationStore {}

MockAppStore createAppStore(SettingsStore settingsStore) {
  final appStore = MockAppStore();
  when(() => appStore.settingsStore).thenReturn(settingsStore);
  return appStore;
}

