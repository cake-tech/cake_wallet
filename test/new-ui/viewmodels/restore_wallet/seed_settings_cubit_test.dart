import "package:cake_wallet/entities/seed_type.dart";
import "package:cake_wallet/new-ui/viewmodels/restore_wallet/seed_settings_cubit.dart";
import "package:cake_wallet/store/seed_settings_store.dart";
import "package:flutter_test/flutter_test.dart";

import "restore_wallet_test_doubles.dart";

void main() {
  late FakeSettingsStore settingsStore;
  late SeedSettingsStore seedSettingsStore;
  late MockAppStore appStore;

  setUp(() {
    settingsStore = FakeSettingsStore(
      moneroSeedType: MoneroSeedType.polyseed,
      bitcoinSeedType: BitcoinSeedType.bip39,
      nanoSeedType: NanoSeedType.bip39,
    );
    seedSettingsStore = SeedSettingsStore()..passphrase = "initial";
    appStore = createAppStore(settingsStore);
  });

  SeedSettingsCubit createCubit() => SeedSettingsCubit(appStore, seedSettingsStore);

  test("initial state mirrors the stores", () async {
    final cubit = createCubit();

    expect(
      cubit.state,
      const SeedSettingsState(
        moneroSeedType: MoneroSeedType.polyseed,
        bitcoinSeedType: BitcoinSeedType.bip39,
        nanoSeedType: NanoSeedType.bip39,
        passphrase: "initial",
      ),
    );
    await cubit.close();
  });

  test("setters write through to the stores and emit once", () async {
    final cubit = createCubit();
    final emitted = <SeedSettingsState>[];
    final subscription = cubit.stream.listen(emitted.add);

    cubit.setMoneroSeedType(MoneroSeedType.bip39);
    cubit.setBitcoinSeedType(BitcoinSeedType.electrum);
    cubit.setNanoSeedType(NanoSeedType.nanoStandard);
    cubit.setPassphrase("secret");
    await pumpEventQueue();

    expect(settingsStore.moneroSeedType, MoneroSeedType.bip39);
    expect(settingsStore.bitcoinSeedType, BitcoinSeedType.electrum);
    expect(settingsStore.nanoSeedType, NanoSeedType.nanoStandard);
    expect(seedSettingsStore.passphrase, "secret");
    expect(emitted, hasLength(4));
    expect(
      emitted.last,
      const SeedSettingsState(
        moneroSeedType: MoneroSeedType.bip39,
        bitcoinSeedType: BitcoinSeedType.electrum,
        nanoSeedType: NanoSeedType.nanoStandard,
        passphrase: "secret",
      ),
    );

    await subscription.cancel();
    await cubit.close();
  });

  test("setPassphrase(null) clears the passphrase", () async {
    final cubit = createCubit()..setPassphrase(null);

    expect(cubit.state.passphrase, isNull);
    expect(seedSettingsStore.passphrase, isNull);
    await cubit.close();
  });

  test("external store changes are mirrored into the state", () async {
    final cubit = createCubit();

    settingsStore.moneroSeedType = MoneroSeedType.legacy;
    settingsStore.bitcoinSeedType = BitcoinSeedType.electrum;
    settingsStore.nanoSeedType = NanoSeedType.nanoStandard;
    seedSettingsStore.passphrase = "from store";

    expect(cubit.state.moneroSeedType, MoneroSeedType.legacy);
    expect(cubit.state.bitcoinSeedType, BitcoinSeedType.electrum);
    expect(cubit.state.nanoSeedType, NanoSeedType.nanoStandard);
    expect(cubit.state.passphrase, "from store");
    await cubit.close();
  });

  test("two instances stay in sync through the stores", () async {
    final restorePageCubit = createCubit();
    final advancedSettingsCubit = createCubit();

    advancedSettingsCubit
      ..setMoneroSeedType(MoneroSeedType.bip39)
      ..setPassphrase("shared");

    expect(restorePageCubit.state.moneroSeedType, MoneroSeedType.bip39);
    expect(restorePageCubit.state.passphrase, "shared");

    restorePageCubit.setPassphrase(null);
    expect(advancedSettingsCubit.state.passphrase, isNull);

    await advancedSettingsCubit.close();
    await restorePageCubit.close();
  });

  test("close disposes the store reactions", () async {
    final cubit = createCubit();
    await cubit.close();

    settingsStore.moneroSeedType = MoneroSeedType.legacy;
    seedSettingsStore.passphrase = "after close";

    expect(cubit.state.moneroSeedType, MoneroSeedType.polyseed);
    expect(cubit.state.passphrase, "initial");
  });

  test("setters after close still write through without emitting", () async {
    final cubit = createCubit();
    await cubit.close();

    expect(() => cubit.setPassphrase(null), returnsNormally);
    expect(seedSettingsStore.passphrase, isNull);
  });
}

