import "dart:async";
import "dart:io";

import "package:cake_wallet/bitcoin/bitcoin.dart" as btc;
import "package:cake_wallet/bitcoin_cash/bitcoin_cash.dart" as bch;
import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/wallet_creation_service.dart";
import "package:cake_wallet/decred/decred.dart" as dcr;
import "package:cake_wallet/dogecoin/dogecoin.dart" as doge;
import "package:cake_wallet/evm/evm.dart" as evm_proxy;
import "package:cake_wallet/monero/monero.dart" as xmr;
import "package:cake_wallet/nano/nano.dart" as xno;
import "package:cake_wallet/new-ui/viewmodels/restore_wallet/seed_settings_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/restore_wallet/wallet_restore_cubit.dart";
import "package:cake_wallet/solana/solana.dart" as sol;
import "package:cake_wallet/store/seed_settings_store.dart";
import "package:cake_wallet/tron/tron.dart" as trx;
import "package:cake_wallet/view_model/restore/restore_mode.dart";
import "package:cake_wallet/view_model/restore/restore_wallet.dart";
import "package:cake_wallet/wownero/wownero.dart" as wow;
import "package:cake_wallet/zano/zano.dart" as zano_proxy;
import "package:cake_wallet/zcash/zcash.dart" as zec;
import "package:cake_wallet/zcash/zcash_network_type.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/db/sqlite.dart" as sqlite;
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_credentials.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

import "restore_wallet_test_doubles.dart";

class _RecordedCredentials extends WalletCredentials {
  _RecordedCredentials(this.factory, this.arguments)
      : super(
          name: arguments["name"] as String,
          height: arguments["height"] as int?,
          password: arguments["password"] as String?,
        );

  final String factory;
  final Map<String, Object?> arguments;
}

class _FakeMonero extends Fake implements xmr.Monero {
  @override
  WalletCredentials createMoneroRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String passphrase,
    required int height,
    required String mnemonic,
  }) =>
      _RecordedCredentials("monero.seed", {
        "name": name,
        "password": password,
        "passphrase": passphrase,
        "height": height,
        "mnemonic": mnemonic,
      });

  @override
  WalletCredentials createMoneroRestoreWalletFromKeysCredentials({
    required String name,
    required String spendKey,
    required String viewKey,
    required String address,
    required String password,
    required String language,
    required int height,
    HardwareWalletType? hardwareWalletType,
  }) =>
      _RecordedCredentials("monero.keys", {
        "name": name,
        "spendKey": spendKey,
        "viewKey": viewKey,
        "address": address,
        "password": password,
        "language": language,
        "height": height,
        "hardwareWalletType": hardwareWalletType,
      });
}

class _FakeWownero extends Fake implements wow.Wownero {
  @override
  WalletCredentials createWowneroRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String passphrase,
    required int height,
    required String mnemonic,
  }) =>
      _RecordedCredentials("wownero.seed", {
        "name": name,
        "password": password,
        "passphrase": passphrase,
        "height": height,
        "mnemonic": mnemonic,
      });

  @override
  WalletCredentials createWowneroRestoreWalletFromKeysCredentials({
    required String name,
    required String spendKey,
    required String viewKey,
    required String address,
    required String password,
    required String language,
    required int height,
  }) =>
      _RecordedCredentials("wownero.keys", {
        "name": name,
        "spendKey": spendKey,
        "viewKey": viewKey,
        "address": address,
        "password": password,
        "language": language,
        "height": height,
      });
}

class _FakeBitcoin extends Fake implements btc.Bitcoin {
  @override
  WalletCredentials createBitcoinRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    required DerivationType derivationType,
    required String derivationPath,
    String? passphrase,
  }) =>
      _RecordedCredentials("bitcoin.seed", {
        "name": name,
        "mnemonic": mnemonic,
        "password": password,
        "derivationType": derivationType,
        "derivationPath": derivationPath,
        "passphrase": passphrase,
      });

  @override
  WalletCredentials createBitcoinWalletFromKeys({
    required String name,
    required String password,
    required String xpub,
    HardwareWalletType? hardwareWalletType,
  }) =>
      _RecordedCredentials("bitcoin.keys", {
        "name": name,
        "password": password,
        "xpub": xpub,
        "hardwareWalletType": hardwareWalletType,
      });

  @override
  WalletCredentials createLitecoinWalletFromKeys({
    required String name,
    required String password,
    required String xpub,
    required String scanSecret,
    required String spendPubkey,
    HardwareWalletType? hardwareWalletType,
  }) =>
      _RecordedCredentials("litecoin.keys", {
        "name": name,
        "password": password,
        "xpub": xpub,
        "scanSecret": scanSecret,
        "spendPubkey": spendPubkey,
        "hardwareWalletType": hardwareWalletType,
      });
}

class _FakeBitcoinCash extends Fake implements bch.BitcoinCash {
  @override
  WalletCredentials createBitcoinCashRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      _RecordedCredentials("bitcoinCash.seed", {
        "name": name,
        "mnemonic": mnemonic,
        "password": password,
        "passphrase": passphrase,
      });
}

class _FakeDogecoin extends Fake implements doge.DogeCoin {
  @override
  WalletCredentials createDogeCoinRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      _RecordedCredentials("dogecoin.seed", {
        "name": name,
        "mnemonic": mnemonic,
        "password": password,
        "passphrase": passphrase,
      });
}

class _FakeNano extends Fake implements xno.Nano {
  @override
  WalletCredentials createNanoRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String mnemonic,
    required DerivationType derivationType,
    String? passphrase,
  }) =>
      _RecordedCredentials("nano.seed", {
        "name": name,
        "password": password,
        "mnemonic": mnemonic,
        "derivationType": derivationType,
        "passphrase": passphrase,
      });

  @override
  WalletCredentials createNanoRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required String seedKey,
    required DerivationType derivationType,
  }) =>
      _RecordedCredentials("nano.keys", {
        "name": name,
        "password": password,
        "seedKey": seedKey,
        "derivationType": derivationType,
      });
}

class _FakeEvm extends Fake implements evm_proxy.EVM {
  @override
  WalletCredentials createEVMRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      _RecordedCredentials("evm.seed", {
        "name": name,
        "mnemonic": mnemonic,
        "password": password,
        "passphrase": passphrase,
      });

  @override
  WalletCredentials createEVMRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      _RecordedCredentials("evm.keys", {
        "name": name,
        "privateKey": privateKey,
        "password": password,
      });
}

class _FakeSolana extends Fake implements sol.Solana {
  @override
  WalletCredentials createSolanaRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      _RecordedCredentials("solana.seed", {
        "name": name,
        "mnemonic": mnemonic,
        "password": password,
        "passphrase": passphrase,
      });

  @override
  WalletCredentials createSolanaRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      _RecordedCredentials("solana.keys", {
        "name": name,
        "privateKey": privateKey,
        "password": password,
      });
}

class _FakeTron extends Fake implements trx.Tron {
  @override
  WalletCredentials createTronRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      _RecordedCredentials("tron.seed", {
        "name": name,
        "mnemonic": mnemonic,
        "password": password,
        "passphrase": passphrase,
      });

  @override
  WalletCredentials createTronRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      _RecordedCredentials("tron.keys", {
        "name": name,
        "privateKey": privateKey,
        "password": password,
      });
}

class _FakeZano extends Fake implements zano_proxy.Zano {
  @override
  WalletCredentials createZanoRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String passphrase,
    required int height,
    required String mnemonic,
  }) =>
      _RecordedCredentials("zano.seed", {
        "name": name,
        "password": password,
        "passphrase": passphrase,
        "height": height,
        "mnemonic": mnemonic,
      });
}

class _FakeDecred extends Fake implements dcr.Decred {
  @override
  WalletCredentials createDecredRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      _RecordedCredentials("decred.seed", {
        "name": name,
        "mnemonic": mnemonic,
        "password": password,
        "passphrase": passphrase,
      });

  @override
  WalletCredentials createDecredRestoreWalletFromPubkeyCredentials({
    required String name,
    required String pubkey,
    required String password,
  }) =>
      _RecordedCredentials("decred.keys", {
        "name": name,
        "pubkey": pubkey,
        "password": password,
      });
}

class _FakeZcash extends Fake implements zec.Zcash {
  @override
  WalletCredentials createZcashRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    required int? height,
    String? passphrase,
    int network = 0,
  }) =>
      _RecordedCredentials("zcash.seed", {
        "name": name,
        "mnemonic": mnemonic,
        "password": password,
        "passphrase": passphrase,
        "height": height,
        "network": network,
      });

  @override
  WalletCredentials createZcashRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
    required int height,
  }) =>
      _RecordedCredentials("zcash.keys", {
        "name": name,
        "privateKey": privateKey,
        "password": password,
        "height": height,
      });
}

class _MockWalletCreationService extends Mock implements WalletCreationService {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _FakeWalletCredentials extends Fake implements WalletCredentials {}

class _FakeWallet extends Fake
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

const _seed = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon "
    "abandon about";
const _password = "wallet password";

void main() {
  late FakeSettingsStore settingsStore;
  late SeedSettingsStore seedSettingsStore;
  late MockAppStore appStore;
  late MockAuthenticationStore authenticationStore;
  late _MockWalletCreationService walletCreationService;
  late SeedSettingsCubit seedSettingsCubit;

  setUpAll(() {
    registerFallbackValue(_FakeWalletCredentials());
    registerFallbackValue(_FakeWallet());
    registerFallbackValue(WalletType.monero);

    xmr.monero = _FakeMonero();
    wow.wownero = _FakeWownero();
    btc.bitcoin = _FakeBitcoin();
    bch.bitcoinCash = _FakeBitcoinCash();
    doge.dogecoin = _FakeDogecoin();
    xno.nano = _FakeNano();
    evm_proxy.evm = _FakeEvm();
    sol.solana = _FakeSolana();
    trx.tron = _FakeTron();
    zano_proxy.zano = _FakeZano();
    dcr.decred = _FakeDecred();
    zec.zcash = _FakeZcash();
  });

  setUp(() {
    settingsStore = FakeSettingsStore();
    seedSettingsStore = SeedSettingsStore();
    appStore = createAppStore(settingsStore);
    authenticationStore = MockAuthenticationStore();
    walletCreationService = _MockWalletCreationService();
    seedSettingsCubit = SeedSettingsCubit(appStore, seedSettingsStore);

    when(() => appStore.authenticationStore).thenReturn(authenticationStore);
    when(() => walletCreationService.changeWalletType(type: any(named: "type"))).thenReturn(null);
  });

  tearDown(() => seedSettingsCubit.close());

  WalletRestoreCubit createCubit(
    WalletType type, {
    RestoredWallet? restoredWallet,
    HardwareWalletType? hardwareWalletType,
  }) =>
      WalletRestoreCubit(
        appStore,
        walletCreationService,
        seedSettingsCubit,
        type: type,
        restoredWallet: restoredWallet,
        hardwareWalletType: hardwareWalletType,
      );

  _RecordedCredentials credentialsFor(
    WalletRestoreCubit cubit,
    Map<String, dynamic> options,
  ) =>
      cubit.getCredentials({"name": "wallet", ...options}) as _RecordedCredentials;

  group("construction", () {
    test("defaults to seed mode with a disabled button", () async {
      final cubit = createCubit(WalletType.monero);

      expect(cubit.state.mode, WalletRestoreMode.seed);
      expect(cubit.state.isButtonEnabled, isFalse);
      expect(cubit.state.executionState, isA<InitialExecutionState>());
      verify(() => walletCreationService.changeWalletType(type: WalletType.monero)).called(1);
      await cubit.close();
    });

    test("restoredWallet in seed mode seeds the passphrase and enables the button", () async {
      final cubit = createCubit(
        WalletType.bitcoin,
        restoredWallet: RestoredWallet(
          restoreMode: WalletRestoreMode.seed,
          type: WalletType.bitcoin,
          name: "qr",
          address: null,
          mnemonicSeed: _seed,
          passphrase: "qr passphrase",
        ),
      );

      expect(cubit.state.isButtonEnabled, isTrue);
      expect(seedSettingsCubit.state.passphrase, "qr passphrase");
      expect(seedSettingsStore.passphrase, "qr passphrase");
      await cubit.close();
    });

    test("restoredWallet in keys mode starts in keys mode and keeps the passphrase", () async {
      seedSettingsCubit.setPassphrase("existing");
      final cubit = createCubit(
        WalletType.monero,
        restoredWallet: RestoredWallet(
          restoreMode: WalletRestoreMode.keys,
          type: WalletType.monero,
          name: "qr",
          address: null,
          passphrase: "ignored",
        ),
      );

      expect(cubit.state.mode, WalletRestoreMode.keys);
      expect(seedSettingsCubit.state.passphrase, "existing");
      await cubit.close();
    });
  });

  group("state mutations", () {
    test("setMode resets the button and both passwords", () async {
      final cubit = createCubit(WalletType.monero)
        ..setButtonEnabled(true)
        ..setWalletPassword("a")
        ..setRepeatedWalletPassword("b")
        ..setMode(WalletRestoreMode.keys);

      expect(cubit.state.mode, WalletRestoreMode.keys);
      expect(cubit.state.isButtonEnabled, isFalse);
      expect(cubit.state.walletPassword, isNull);
      expect(cubit.state.repeatedWalletPassword, isNull);
      await cubit.close();
    });

    test("setMode with the current mode is a no-op", () async {
      final cubit = createCubit(WalletType.monero)..setButtonEnabled(true);
      final emitted = <WalletRestoreState>[];
      final subscription = cubit.stream.listen(emitted.add);

      cubit.setMode(WalletRestoreMode.seed);
      await pumpEventQueue();

      expect(emitted, isEmpty);
      expect(cubit.state.isButtonEnabled, isTrue);
      await subscription.cancel();
      await cubit.close();
    });

    test("toggleUseTestnet toggles on null and applies explicit values", () async {
      final cubit = createCubit(WalletType.bitcoin)..toggleUseTestnet(null);
      expect(cubit.state.useTestnet, isTrue);

      cubit.toggleUseTestnet(null);
      expect(cubit.state.useTestnet, isFalse);

      cubit.toggleUseTestnet(true);
      expect(cubit.state.useTestnet, isTrue);
      await cubit.close();
    });

    test("setZcashNetwork stores the network", () async {
      final cubit = createCubit(WalletType.zcash)..setZcashNetwork(ZcashNetworkType.testnet);

      expect(cubit.state.zcashNetwork, ZcashNetworkType.testnet);
      await cubit.close();
    });

    test("mutations after close do not throw", () async {
      final cubit = createCubit(WalletType.monero);
      await cubit.close();

      expect(() => cubit.setButtonEnabled(true), returnsNormally);
      expect(() => cubit.resetExecutionState(), returnsNormally);
    });
  });

  group("getCredentials in seed mode", () {
    final derivation = DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/0'",
    );

    final cases = <WalletType, String>{
      WalletType.monero: "monero.seed",
      WalletType.bitcoin: "bitcoin.seed",
      WalletType.litecoin: "bitcoin.seed",
      WalletType.bitcoinCash: "bitcoinCash.seed",
      WalletType.dogecoin: "dogecoin.seed",
      WalletType.nano: "nano.seed",
      WalletType.banano: "nano.seed",
      WalletType.ethereum: "evm.seed",
      WalletType.polygon: "evm.seed",
      WalletType.base: "evm.seed",
      WalletType.arbitrum: "evm.seed",
      WalletType.bsc: "evm.seed",
      WalletType.robinhood: "evm.seed",
      WalletType.solana: "solana.seed",
      WalletType.tron: "tron.seed",
      WalletType.wownero: "wownero.seed",
      WalletType.zano: "zano.seed",
      WalletType.decred: "decred.seed",
      WalletType.zcash: "zcash.seed",
    };

    for (final entry in cases.entries) {
      test("${entry.key} uses ${entry.value}", () async {
        final cubit = createCubit(entry.key)..setWalletPassword(_password);

        final credentials = credentialsFor(cubit, {
          "seed": _seed,
          "passphrase": "pass",
          "height": 42,
          "derivationInfo": derivation,
        });

        expect(credentials.factory, entry.value);
        expect(credentials.arguments["name"], "wallet");
        expect(credentials.arguments["mnemonic"], _seed);
        expect(credentials.arguments["password"], _password);
        expect(credentials.arguments["passphrase"], "pass");
        await cubit.close();
      });
    }

    test("bitcoin passes the chosen derivation", () async {
      final cubit = createCubit(WalletType.bitcoin);

      final credentials = credentialsFor(cubit, {"seed": _seed, "derivationInfo": derivation});

      expect(credentials.arguments["derivationType"], DerivationType.bip39);
      expect(credentials.arguments["derivationPath"], "m/84'/0'/0'");
      await cubit.close();
    });

    test("monero defaults a missing passphrase to empty and keeps the height", () async {
      final cubit = createCubit(WalletType.monero);

      final credentials = credentialsFor(cubit, {"seed": _seed, "height": 1234});

      expect(credentials.arguments["passphrase"], "");
      expect(credentials.arguments["height"], 1234);
      await cubit.close();
    });

    test("zcash forwards the selected network", () async {
      final cubit = createCubit(WalletType.zcash)..setZcashNetwork(ZcashNetworkType.testnet);

      final credentials = credentialsFor(cubit, {"seed": _seed});

      expect(credentials.arguments["network"], ZcashNetworkType.testnet);
      await cubit.close();
    });

    test("zano attaches the derivation to the credentials", () async {
      final cubit = createCubit(WalletType.zano);

      final credentials = credentialsFor(cubit, {"seed": _seed, "derivationInfo": derivation});

      expect(credentials.derivationInfo, same(derivation));
      await cubit.close();
    });

    test("a generated password is used when none was entered", () async {
      final cubit = createCubit(WalletType.solana);

      final credentials = credentialsFor(cubit, {"seed": _seed});

      expect(credentials.arguments["password"], isA<String>());
      expect(credentials.arguments["password"], isNotEmpty);
      await cubit.close();
    });

    test("haven is rejected", () async {
      final cubit = createCubit(WalletType.haven);

      expect(
        () => cubit.getCredentials({"name": "wallet", "seed": _seed}),
        throwsA(isA<BadWalletTypeException>()),
      );
      await cubit.close();
    });
  });

  group("getCredentials in keys mode", () {
    final nanoDerivation = DerivationInfo(derivationType: DerivationType.nano);

    final cases = <WalletType, String>{
      WalletType.bitcoin: "bitcoin.keys",
      WalletType.litecoin: "litecoin.keys",
      WalletType.monero: "monero.keys",
      WalletType.nano: "nano.keys",
      WalletType.ethereum: "evm.keys",
      WalletType.polygon: "evm.keys",
      WalletType.base: "evm.keys",
      WalletType.arbitrum: "evm.keys",
      WalletType.bsc: "evm.keys",
      WalletType.robinhood: "evm.keys",
      WalletType.solana: "solana.keys",
      WalletType.tron: "tron.keys",
      WalletType.wownero: "wownero.keys",
      WalletType.decred: "decred.keys",
      WalletType.zcash: "zcash.keys",
    };

    for (final entry in cases.entries) {
      test("${entry.key} uses ${entry.value}", () async {
        final cubit = createCubit(entry.key, hardwareWalletType: HardwareWalletType.cupcake)
          ..setMode(WalletRestoreMode.keys)
          ..setWalletPassword(_password);

        final credentials = credentialsFor(cubit, {
          "viewKey": "view",
          "spendKey": "spend",
          "scanSecret": "scan",
          "spendPubkey": "spendPub",
          "address": "address",
          "private_key": "private",
          "height": 7,
          "derivationInfo": nanoDerivation,
        });

        expect(credentials.factory, entry.value);
        expect(credentials.arguments["password"], _password);
        await cubit.close();
      });
    }

    test("monero passes view key, spend key, address and hardware type", () async {
      final cubit = createCubit(WalletType.monero, hardwareWalletType: HardwareWalletType.cupcake)
        ..setMode(WalletRestoreMode.keys);

      final credentials = credentialsFor(cubit, {
        "viewKey": "view",
        "spendKey": "spend",
        "address": "address",
        "height": 7,
      });

      expect(credentials.arguments["viewKey"], "view");
      expect(credentials.arguments["spendKey"], "spend");
      expect(credentials.arguments["address"], "address");
      expect(credentials.arguments["language"], "English");
      expect(credentials.arguments["height"], 7);
      expect(credentials.arguments["hardwareWalletType"], HardwareWalletType.cupcake);
      await cubit.close();
    });

    test("nano passes the seed key and derivation type", () async {
      final cubit = createCubit(WalletType.nano)..setMode(WalletRestoreMode.keys);

      final credentials = credentialsFor(cubit, {
        "private_key": "seedkey",
        "derivationInfo": nanoDerivation,
      });

      expect(credentials.arguments["seedKey"], "seedkey");
      expect(credentials.arguments["derivationType"], DerivationType.nano);
      await cubit.close();
    });

    test("bitcoin cash has no keys restore", () async {
      final cubit = createCubit(WalletType.bitcoinCash)..setMode(WalletRestoreMode.keys);

      expect(
        () => cubit.getCredentials({"name": "wallet"}),
        throwsA(isA<BadWalletTypeException>()),
      );
      await cubit.close();
    });
  });

  group("restore", () {
    test("emits executing then a failure with the error message", () async {
      when(() => walletCreationService.checkIfExists(any()))
          .thenThrow(WalletExistsException("taken"));
      final cubit = createCubit(WalletType.monero)
        ..setWalletPassword(_password)
        ..setRepeatedWalletPassword(_password);
      final emitted = <ExecutionState>[];
      final subscription = cubit.stream.map((state) => state.executionState).listen(emitted.add);

      await cubit.restore({"name": "taken", "seed": _seed});
      await pumpEventQueue();

      expect(emitted, [isA<IsExecutingState>(), isA<FailureState>()]);
      expect((emitted.last as FailureState).error, contains("taken"));
      await subscription.cancel();
      await cubit.close();
    });

    test("two consecutive identical failures are both emitted", () async {
      when(() => walletCreationService.checkIfExists(any()))
          .thenThrow(WalletExistsException("taken"));
      final cubit = createCubit(WalletType.monero)
        ..setWalletPassword(_password)
        ..setRepeatedWalletPassword(_password);
      final failures = <FailureState>[];
      final subscription = cubit.stream
          .map((state) => state.executionState)
          .where((state) => state is FailureState)
          .cast<FailureState>()
          .listen(failures.add);

      await cubit.restore({"name": "taken", "seed": _seed});
      await cubit.restore({"name": "taken", "seed": _seed});
      await pumpEventQueue();

      expect(failures, hasLength(2));
      await subscription.cancel();
      await cubit.close();
    });

    test("startExecuting before restore does not emit a second executing state", () async {
      when(() => walletCreationService.checkIfExists(any()))
          .thenThrow(WalletExistsException("taken"));
      final cubit = createCubit(WalletType.monero)
        ..setWalletPassword(_password)
        ..setRepeatedWalletPassword(_password);
      final emitted = <ExecutionState>[];
      final subscription = cubit.stream.map((state) => state.executionState).listen(emitted.add);

      cubit.startExecuting();
      await cubit.restore({"name": "taken", "seed": _seed});
      await pumpEventQueue();

      expect(emitted, [isA<IsExecutingState>(), isA<FailureState>()]);
      await subscription.cancel();
      await cubit.close();
    });

    test("a second restore while one is running is ignored", () async {
      final checkStarted = Completer<void>();
      final releaseCheck = Completer<void>();
      when(() => walletCreationService.checkIfExists(any())).thenAnswer((_) async {
        checkStarted.complete();
        await releaseCheck.future;
        throw WalletExistsException("taken");
      });
      final cubit = createCubit(WalletType.monero)
        ..setWalletPassword(_password)
        ..setRepeatedWalletPassword(_password);

      final first = cubit.restore({"name": "taken", "seed": _seed});
      await checkStarted.future;
      await cubit.restore({"name": "taken", "seed": _seed});
      releaseCheck.complete();
      await first;

      verify(() => walletCreationService.checkIfExists(any())).called(1);
      await cubit.close();
    });

    test("closing the cubit mid-restore does not throw", () async {
      final releaseCheck = Completer<void>();
      when(() => walletCreationService.checkIfExists(any())).thenAnswer((_) async {
        await releaseCheck.future;
        throw WalletExistsException("taken");
      });
      final cubit = createCubit(WalletType.monero)
        ..setWalletPassword(_password)
        ..setRepeatedWalletPassword(_password);

      final pending = cubit.restore({"name": "taken", "seed": _seed});
      await cubit.close();
      releaseCheck.complete();

      await expectLater(pending, completes);
    });

    group("with storage", () {
      late Directory appDirectory;

      setUpAll(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
        appDirectory = Directory.systemTemp.createTempSync("cw_wallet_restore_cubit_test");
        Directory("${appDirectory.path}/cake_wallet").createSync(recursive: true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel("plugins.flutter.io/path_provider"),
          (_) async => appDirectory.path,
        );
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        await sqlite.initDb();
      });

      tearDownAll(() async {
        await sqlite.db?.close();
        sqlite.db = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel("plugins.flutter.io/path_provider"),
          null,
        );
        appDirectory.deleteSync(recursive: true);
      });

      test("success saves the wallet, switches to it and emits success", () async {
        final wallet = _MockWallet();
        final walletAddresses = _MockWalletAddresses();
        when(() => walletAddresses.address).thenReturn("restored address");
        when(() => walletAddresses.primaryAddress).thenReturn("restored address");
        when(() => wallet.seed).thenReturn(_seed);
        when(() => wallet.walletAddresses).thenReturn(walletAddresses);
        when(() => wallet.save()).thenAnswer((_) async {});
        when(() => walletCreationService.checkIfExists(any())).thenAnswer((_) async {});
        when(() => walletCreationService.typeExists(any())).thenAnswer((_) async => false);
        when(
          () => walletCreationService.restoreFromSeed(any(), isTestnet: any(named: "isTestnet")),
        ).thenAnswer((_) async => wallet);
        when(() => appStore.changeCurrentWallet(any())).thenAnswer((_) async {});
        when(() => authenticationStore.allowedCreate()).thenReturn(null);

        final cubit = createCubit(WalletType.monero)
          ..setWalletPassword(_password)
          ..setRepeatedWalletPassword(_password)
          ..toggleUseTestnet(true);
        final emitted = <ExecutionState>[];
        final subscription = cubit.stream.map((state) => state.executionState).listen(emitted.add);

        await cubit.restore({"name": "restored", "seed": _seed, "height": 10});
        await pumpEventQueue();

        expect(emitted.last, isA<ExecutedSuccessfullyState>());
        final captured = verify(
          () => walletCreationService.restoreFromSeed(captureAny(), isTestnet: true),
        ).captured;
        final credentials = captured.single as WalletCredentials;
        expect(credentials.walletInfo!.name, "restored");
        expect(credentials.walletInfo!.isRecovery, isTrue);
        expect(credentials.walletInfo!.address, "restored address");
        expect(credentials.walletInfo!.isNonSeedWallet, isFalse);
        expect(credentials.walletInfo!.path, endsWith("/restored/restored"));
        verify(() => wallet.save()).called(1);
        verify(() => appStore.changeCurrentWallet(wallet)).called(1);
        verify(() => authenticationStore.allowedCreate()).called(1);

        await subscription.cancel();
        await cubit.close();
      });
    });
  });
}
