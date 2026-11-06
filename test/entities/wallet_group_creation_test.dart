import "dart:io";

import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/new_wallet_arguments.dart";
import "package:cake_wallet/core/wallet_creation_service.dart";
import "package:cw_core/wallet_group_db_entry.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/authentication_store.dart";
import "package:cake_wallet/view_model/advanced_privacy_settings_view_model.dart";
import "package:cake_wallet/view_model/seed_settings_view_model.dart";
import "package:cake_wallet/view_model/wallet_new_vm.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_credentials.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

class _MockAppStore extends Mock implements AppStore {}

class _MockAuthenticationStore extends Mock implements AuthenticationStore {}

class _MockWalletCreationService extends Mock implements WalletCreationService {}

class _MockSeedSettingsViewModel extends Mock implements SeedSettingsViewModel {}

class _MockAdvancedPrivacySettingsViewModel extends Mock
    implements AdvancedPrivacySettingsViewModel {}

class _MockWallet extends Mock implements WalletBase {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _TestCredentials extends WalletCredentials {
  _TestCredentials(String name)
      : super(
          name: name,
          derivationInfo: DerivationInfo(
            derivationType: DerivationType.bip39,
            derivationPath: "m/44'/60'/0'/0/0",
          ),
        );
}

/// The real create flow, with only the chain-specific credentials stubbed out.
class _TestWalletNewVM extends WalletNewVM {
  _TestWalletNewVM(
    AppStore appStore,
    WalletCreationService service,
    NewWalletArguments args,
  ) : super(
          appStore,
          service,
          _MockAdvancedPrivacySettingsViewModel(),
          _MockSeedSettingsViewModel(),
          newWalletArguments: args,
        );

  @override
  WalletCredentials getCredentials(dynamic options) => _TestCredentials(name);
}

Future<void> main() async {
  final dataRoot = Directory("./test/data/wallet_group_creation");

  late _MockAppStore appStore;
  late _MockWalletCreationService service;

  /// groupId each wallet had when the chain wallet was created (before the info is saved).
  final groupIdDuringProcess = <String, String?>{};

  setUpAll(() async {
    registerFallbackValue(_TestCredentials("fallback"));
    registerFallbackValue(_MockWallet());
    registerFallbackValue(WalletType.bitcoin);

    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
    dataRoot.createSync(recursive: true);
    Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);

    PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initDb();
  });

  setUp(() async {
    await db!.delete(WalletInfo.tableName);
    await db!.delete(DerivationInfo.tableName);
    await db!.delete(WalletGroupDbEntry.tableName);
    groupIdDuringProcess.clear();

    final authenticationStore = _MockAuthenticationStore();
    appStore = _MockAppStore();
    when(() => appStore.authenticationStore).thenReturn(authenticationStore);
    when(() => appStore.changeCurrentWallet(any())).thenAnswer((_) async {});

    service = _MockWalletCreationService();
    when(() => service.checkIfExists(any())).thenAnswer((_) async {});
    when(() => service.typeExists(any())).thenAnswer((_) async => false);
    when(() => service.create(any(), isTestnet: any(named: "isTestnet")))
        .thenAnswer((invocation) async {
      final credentials = invocation.positionalArguments.first as WalletCredentials;
      final info = credentials.walletInfo!;
      groupIdDuringProcess[info.name] = info.groupId;

      final addresses = _MockWalletAddresses();
      when(() => addresses.address).thenReturn("addr_${info.name}");
      final wallet = _MockWallet();
      when(() => wallet.walletAddresses).thenReturn(addresses);
      when(() => wallet.save()).thenAnswer((_) async {});
      return wallet;
    });
  });

  tearDownAll(() async {
    await db?.close();
    db = null;
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });

  Future<WalletInfo> create(String name, WalletType type, {String? parentGroupId}) async {
    final vm = _TestWalletNewVM(
      appStore,
      service,
      NewWalletArguments(type: type, parentGroupId: parentGroupId),
    )
      ..name = name
      // Linux CI uses direct password input, which requires a password.
      ..walletPassword = "password"
      ..repeatedWalletPassword = "password";

    await vm.create();

    final state = vm.state;
    expect(state, isA<ExecutedSuccessfullyState>(),
        reason: state is FailureState ? state.error : null);
    expect(groupIdDuringProcess[name], isNull,
        reason: "the group must be assigned after the chain wallet is created");
    return (await WalletInfo.get(name, type))!;
  }

  test("a new wallet gets its own group named after it", () async {
    final wallet = await create("Main", WalletType.ethereum);

    expect(wallet.groupId, isNotNull);
    expect(wallet.hashedWalletIdentifier, isNull);
    final group = await WalletGroupDbEntry.get(wallet.groupId!);
    expect(group!.name, "Main");

    final other = await create("Second", WalletType.solana);
    expect(other.groupId, isNot(wallet.groupId));
    expect((await WalletGroupDbEntry.getAll()).length, 2);
  });

  test("add-to-group joins the parent's group", () async {
    final parent = await create("Main", WalletType.ethereum);

    final child = await create("Main SOL", WalletType.solana, parentGroupId: parent.groupId);

    expect(child.groupId, parent.groupId);
    expect((await WalletGroupDbEntry.getAll()).length, 1);
  });
}
