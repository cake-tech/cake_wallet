import "package:cake_wallet/core/wallet_network.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/manage_builtin_networks_cubit.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableSet;
import "package:mocktail/mocktail.dart";

class _MockSettingsStore extends Mock implements SettingsStore {}

void main() {
  late _MockSettingsStore settingsStore;

  setUp(() {
    settingsStore = _MockSettingsStore();
    when(() => settingsStore.setHiddenBuiltinNetworks(any())).thenReturn(null);
  });

  setUpAll(() => registerFallbackValue(<WalletType>{}));

  group("ManageBuiltinNetworksCubit", () {
    test("starts from the stored hidden set and lists every built-in network but evm", () {
      when(() => settingsStore.hiddenBuiltinNetworks)
          .thenReturn(ObservableSet.of({WalletType.tron}));

      final cubit = ManageBuiltinNetworksCubit(settingsStore);

      expect(cubit.state.networks, builtinNetworkTypes);
      expect(cubit.state.networks, isNot(contains(WalletType.evm)));
      expect(cubit.state.hiddenNetworks, {WalletType.tron});
      expect(cubit.state.isVisible(WalletType.tron), isFalse);
      expect(cubit.state.isVisible(WalletType.bitcoin), isTrue);
    });

    test("hiding a visible network writes the grown set to the store", () {
      when(() => settingsStore.hiddenBuiltinNetworks)
          .thenReturn(ObservableSet.of({WalletType.tron}));
      final cubit = ManageBuiltinNetworksCubit(settingsStore);

      cubit.toggleVisibility(WalletType.solana);

      expect(cubit.state.hiddenNetworks, {WalletType.tron, WalletType.solana});
      verify(() => settingsStore.setHiddenBuiltinNetworks({WalletType.tron, WalletType.solana}))
          .called(1);
    });

    test("showing a hidden network removes it from the stored set", () {
      when(() => settingsStore.hiddenBuiltinNetworks)
          .thenReturn(ObservableSet.of({WalletType.tron, WalletType.zano}));
      final cubit = ManageBuiltinNetworksCubit(settingsStore);

      cubit.toggleVisibility(WalletType.zano);

      expect(cubit.state.hiddenNetworks, {WalletType.tron});
      verify(() => settingsStore.setHiddenBuiltinNetworks({WalletType.tron})).called(1);
    });

    test("the store's own set is not mutated before the write", () {
      final stored = ObservableSet.of({WalletType.tron});
      when(() => settingsStore.hiddenBuiltinNetworks).thenReturn(stored);
      final cubit = ManageBuiltinNetworksCubit(settingsStore);

      cubit.toggleVisibility(WalletType.solana);

      expect(stored, {WalletType.tron});
    });

    test("hiding the last visible network is refused and nothing is written", () async {
      final lastVisible = builtinNetworkTypes.first;
      when(() => settingsStore.hiddenBuiltinNetworks).thenReturn(
        ObservableSet.of(builtinNetworkTypes.where((type) => type != lastVisible)),
      );
      final cubit = ManageBuiltinNetworksCubit(settingsStore);
      final presented = <ManageBuiltinNetworksPresentation>[];
      final subscription = cubit.presentation.listen(presented.add);

      cubit.toggleVisibility(lastVisible);
      await Future<void>.delayed(Duration.zero);

      expect(presented, [isA<LastVisibleNetworkHideRefused>()]);
      expect(cubit.state.visibleCount, 1);
      expect(cubit.state.isVisible(lastVisible), isTrue);
      verifyNever(() => settingsStore.setHiddenBuiltinNetworks(any()));

      await subscription.cancel();
      await cubit.close();
    });

    test("with the last visible network left, showing another one is still allowed", () {
      final lastVisible = builtinNetworkTypes.first;
      final hiddenOne = builtinNetworkTypes.last;
      when(() => settingsStore.hiddenBuiltinNetworks).thenReturn(
        ObservableSet.of(builtinNetworkTypes.where((type) => type != lastVisible)),
      );
      final cubit = ManageBuiltinNetworksCubit(settingsStore);

      cubit.toggleVisibility(hiddenOne);

      expect(cubit.state.visibleCount, 2);
      expect(cubit.state.isVisible(hiddenOne), isTrue);
    });
  });
}
