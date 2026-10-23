import "dart:convert";
import "dart:io";

import "package:cake_wallet/core/backup/app_backup_contents.dart";
import "package:cake_wallet/core/backup/app_backup_preferences.dart";
import "package:cake_wallet/core/backup/app_backup_storage.dart";
import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/entities/secret_store_key.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup/app_backup_bloc.dart";
import "package:crypto/crypto.dart";
import "package:cw_core/db/sqlite.dart" as sqlite;
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:plugin_platform_interface/plugin_platform_interface.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _MockBackupService extends Mock implements BackupServiceV3 {}

class _MockPreferences extends Mock implements AppBackupPreferences {}

class _MockStorageService extends Mock implements AppBackupStorageService {}

class _MockContents extends Mock implements AppBackupContents {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.documents);

  final String documents;

  @override
  Future<String?> getApplicationDocumentsPath() async => documents;
}

WalletInfo _wallet(String id) => WalletInfo.external(
      id: id,
      name: "wallet $id",
      type: WalletType.bitcoin,
      isRecovery: false,
      restoreHeight: 0,
      date: DateTime(2026),
      dirPath: "",
      path: "",
      address: "address-$id",
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File backupFile;
  late _MockBackupService backupService;
  late _MockPreferences preferences;
  late _MockStorageService storageService;
  late _MockContents contents;
  late _MockSecureStorage secureStorage;
  late WalletInfo walletA;
  late WalletInfo walletB;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(_wallet("fallback"));
    registerFallbackValue(<String>{});
    registerFallbackValue(File(""));
    registerFallbackValue(AppBackupStorage.custom);
    registerFallbackValue(AppBackupRecord(createdAt: DateTime(2026), sizeInBytes: 0));
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync("app_backup_bloc_test");
    backupFile = File("${tempDir.path}/backup.zip");
    PathProviderPlatform.instance =
        _FakePathProvider((Directory("${tempDir.path}/documents")..createSync()).path);
    await sqlite.initDb();
    walletA = _wallet("a");
    walletB = _wallet("b");
    await walletA.save();
    await walletB.save();

    backupService = _MockBackupService();
    preferences = _MockPreferences();
    storageService = _MockStorageService();
    contents = _MockContents();
    secureStorage = _MockSecureStorage();

    when(() => secureStorage.read(key: any(named: "key"))).thenAnswer((_) async => "Cat1-Dog2");
    when(() => secureStorage.delete(key: any(named: "key"))).thenAnswer((_) async {});
    when(() => secureStorage.write(key: any(named: "key"), value: any(named: "value")))
        .thenAnswer((_) async {});
    when(() => contents.excludedWalletIds()).thenAnswer((_) async => {"b"});
    when(() => contents.sharedSize()).thenAnswer((_) async => 100);
    when(() => contents.walletSize(any())).thenAnswer(
      (invocation) async => (invocation.positionalArguments.single as WalletInfo).id == "a" ? 10 : 20,
    );
    when(() => preferences.preferredStorage).thenReturn(null);
    when(() => preferences.lastBackup).thenReturn(null);
    when(() => preferences.isSetupCompleted).thenReturn(false);
    when(() => preferences.setExcludedWalletIds(any())).thenAnswer((_) async {});
    when(() => preferences.setPreferredStorage(any())).thenAnswer((_) async {});
    when(() => preferences.recordBackup(any())).thenAnswer((_) async {});
    when(() => preferences.completeSetup()).thenAnswer((_) async {});
    when(() => storageService.availableStorages())
        .thenAnswer((_) async => [AppBackupStorage.cloud, AppBackupStorage.custom]);
    when(() => storageService.clearOutputs()).thenAnswer((_) async {});
    when(() => storageService.keepsFileAfterSave(any())).thenReturn(false);
    when(() => storageService.newBackupPath()).thenAnswer((_) async => backupFile.path);
    when(
      () => backupService.exportBackupFile(
        any(),
        excludedWalletIds: any(named: "excludedWalletIds"),
        outputPath: any(named: "outputPath"),
      ),
    ).thenAnswer((_) async => backupFile..writeAsStringSync("backup"));
  });

  tearDown(() async {
    await sqlite.db?.close();
    sqlite.db = null;
    tempDir.deleteSync(recursive: true);
  });

  AppBackupBloc createBloc() =>
      AppBackupBloc(backupService, preferences, storageService, contents, secureStorage);

  Future<AppBackupBloc> loadedBloc() async {
    final bloc = createBloc();
    await bloc.stream.firstWhere((state) => state.totalSize != null);
    return bloc;
  }

  Future<AppBackupState> next(AppBackupBloc bloc) => bloc.stream.first;

  Future<List<AppBackupState>> statesUntil(AppBackupBloc bloc, AppBackupStatus status) async {
    final states = <AppBackupState>[];
    await for (final state in bloc.stream) {
      states.add(state);
      if (state.status == status) break;
    }
    return states;
  }

  void stubSave(AppBackupStorage storage, bool saved) =>
      when(() => storageService.save(backupFile, storage)).thenAnswer((_) async => saved);

  test("loads wallets, saved exclusions, password and sizes", () async {
    final bloc = await loadedBloc();

    expect(bloc.state.status, AppBackupStatus.idle);
    expect(bloc.state.password, "Cat1-Dog2");
    expect(bloc.state.isSelected(walletA), isTrue);
    expect(bloc.state.isSelected(walletB), isFalse);
    expect(bloc.state.totalSize, 110);
    expect(bloc.state.preferredStorage, AppBackupStorage.cloud);
    await bloc.close();
  });

  test("selection changes update the state directly and are saved", () async {
    final bloc = await loadedBloc();

    bloc.add(WalletToggled("b"));
    final toggled = await next(bloc);
    expect(toggled.excludedWalletIds, isEmpty);
    expect(toggled.totalSize, 130);
    verify(() => preferences.setExcludedWalletIds(<String>{})).called(1);

    bloc.add(AllWalletsDeselected());
    final deselected = await next(bloc);
    expect(deselected.canContinue, isFalse);
    expect(deselected.selectedCount, 0);
    verifyNever(() => preferences.setExcludedWalletIds({"a", "b"}));

    bloc.add(WalletToggled("b"));
    await next(bloc);
    verify(() => preferences.setExcludedWalletIds({"a"})).called(1);
    bloc.add(WalletToggled("b"));
    await next(bloc);
    verifyNever(() => preferences.setExcludedWalletIds({"a", "b"}));

    bloc.add(BackupNowRequested());
    await Future<void>.delayed(Duration.zero);
    verifyNever(
      () => backupService.exportBackupFile(
        any(),
        excludedWalletIds: any(named: "excludedWalletIds"),
        outputPath: any(named: "outputPath"),
      ),
    );

    bloc.add(AllWalletsSelected());
    expect((await next(bloc)).canContinue, isTrue);
    await bloc.close();
  });

  test("shows the password mismatch only after submitting and clears it on edit", () async {
    final bloc = await loadedBloc();

    bloc.add(VerificationChanged("Cat1-Dog3"));
    expect((await next(bloc)).showMismatch, isFalse);

    bloc.add(VerificationSubmitted());
    final submitted = await next(bloc);
    expect(submitted.showMismatch, isTrue);
    expect(submitted.canSubmitVerification, isFalse);

    bloc.add(VerificationChanged("Cat1-Dog2"));
    final corrected = await next(bloc);
    expect(corrected.showMismatch, isFalse);
    expect(corrected.passwordMatches, isTrue);
    await bloc.close();
  });

  test("setup creates the backup, waits for a storage and completes once saved", () async {
    final bloc = await loadedBloc();
    bloc.add(VerificationChanged("Cat1-Dog2"));
    await next(bloc);

    bloc.add(VerificationSubmitted());
    final created = await statesUntil(bloc, AppBackupStatus.readyToSave);
    expect(created.map((state) => state.status),
        [AppBackupStatus.creating, AppBackupStatus.readyToSave]);
    expect(created.last.backupFile, backupFile);
    verify(
      () => backupService.exportBackupFile(
        "Cat1-Dog2",
        excludedWalletIds: {"b"},
        outputPath: backupFile.path,
      ),
    ).called(1);

    stubSave(AppBackupStorage.custom, false);
    bloc.add(SaveRequested(AppBackupStorage.custom));
    final cancelled = await statesUntil(bloc, AppBackupStatus.readyToSave);
    expect(cancelled.first.status, AppBackupStatus.saving);
    expect(backupFile.existsSync(), isTrue);
    verifyNever(() => preferences.completeSetup());

    stubSave(AppBackupStorage.custom, true);
    bloc.add(SaveRequested(AppBackupStorage.custom));
    final saved = (await statesUntil(bloc, AppBackupStatus.saved)).last;
    expect(saved.isSetupCompleted, isTrue);
    expect(saved.preferredStorage, AppBackupStorage.custom);
    expect(saved.lastBackup, isNotNull);
    expect(saved.backupFile, isNull);
    expect(backupFile.existsSync(), isFalse);
    verify(() => preferences.setPreferredStorage(AppBackupStorage.custom)).called(1);
    verify(() => preferences.completeSetup()).called(1);
    final recorded =
        verify(() => preferences.recordBackup(captureAny())).captured.single as AppBackupRecord;
    expect(recorded.sizeInBytes, 6);
    expect(recorded.sha256Hash, sha256.convert(utf8.encode("backup")).toString());
    await bloc.close();
  });

  test("a regenerated password is saved only once it's verified", () async {
    when(() => preferences.isSetupCompleted).thenReturn(true);
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final bloc = await loadedBloc();
    bloc.add(VerificationChanged("leftover"));
    await next(bloc);

    bloc.add(PasswordRegenerationRequested());
    final regenerated = await next(bloc);
    final newPassword = regenerated.pendingPassword!;
    expect(newPassword, matches(RegExp(r"^([A-Z][a-z]+[0-9]-){7}[A-Z][a-z]+[0-9]$")));
    expect(regenerated.password, "Cat1-Dog2");
    expect(regenerated.passwordToVerify, newPassword);
    expect(regenerated.verificationInput, isEmpty);

    bloc.add(VerificationChanged("Cat1-Dog2"));
    await next(bloc);
    bloc.add(VerificationSubmitted());
    expect((await next(bloc)).showMismatch, isTrue);
    verifyNever(() => secureStorage.write(key: key, value: any(named: "value")));

    bloc.add(VerificationChanged(newPassword));
    await next(bloc);
    bloc.add(VerificationSubmitted());
    final saved = await next(bloc);
    expect(saved.password, newPassword);
    expect(saved.pendingPassword, isNull);
    expect(saved.status, AppBackupStatus.idle);
    verify(() => secureStorage.write(key: key, value: newPassword)).called(1);
    verifyNever(
      () => backupService.exportBackupFile(
        any(),
        excludedWalletIds: any(named: "excludedWalletIds"),
        outputPath: any(named: "outputPath"),
      ),
    );
    await bloc.close();
  });

  test("a failed export reports the error and goes back to idle", () async {
    when(
      () => backupService.exportBackupFile(
        any(),
        excludedWalletIds: any(named: "excludedWalletIds"),
        outputPath: any(named: "outputPath"),
      ),
    ).thenThrow(StateError("disk full"));
    final bloc = await loadedBloc();
    bloc.add(VerificationChanged("Cat1-Dog2"));
    await next(bloc);

    bloc.add(VerificationSubmitted());
    final states = await statesUntil(bloc, AppBackupStatus.idle);
    expect(states.map((state) => state.status),
        [AppBackupStatus.creating, AppBackupStatus.failed, AppBackupStatus.idle]);
    expect(states[1].error, contains("disk full"));
    await bloc.close();
  });

  test("backup now saves straight to the preferred storage", () async {
    when(() => preferences.isSetupCompleted).thenReturn(true);
    when(() => preferences.preferredStorage).thenReturn(AppBackupStorage.custom);
    stubSave(AppBackupStorage.custom, true);
    final bloc = await loadedBloc();

    bloc.add(BackupNowRequested());
    final states = await statesUntil(bloc, AppBackupStatus.saved);
    expect(states.map((state) => state.status).toSet(),
        {AppBackupStatus.creating, AppBackupStatus.saving, AppBackupStatus.saved});
    expect(states.any((state) => state.status == AppBackupStatus.readyToSave), isFalse);
    verify(() => storageService.save(backupFile, AppBackupStorage.custom)).called(1);
    expect(backupFile.existsSync(), isFalse);
    await bloc.close();
  });

  test("a backup handed to another app keeps its file after saving", () async {
    when(() => preferences.isSetupCompleted).thenReturn(true);
    when(() => preferences.preferredStorage).thenReturn(AppBackupStorage.cloud);
    when(() => storageService.keepsFileAfterSave(AppBackupStorage.cloud)).thenReturn(true);
    stubSave(AppBackupStorage.cloud, true);
    final bloc = await loadedBloc();

    bloc.add(BackupNowRequested());
    await statesUntil(bloc, AppBackupStatus.saved);
    expect(backupFile.existsSync(), isTrue);
    await bloc.close();
    expect(backupFile.existsSync(), isTrue);
  });

  test("a cancelled backup now deletes the file and goes back to idle", () async {
    when(() => preferences.isSetupCompleted).thenReturn(true);
    stubSave(AppBackupStorage.cloud, false);
    final bloc = await loadedBloc();

    bloc.add(BackupNowRequested());
    await statesUntil(bloc, AppBackupStatus.idle);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.backupFile, isNull);
    expect(backupFile.existsSync(), isFalse);
    verifyNever(() => preferences.recordBackup(any()));
    await bloc.close();
  });
}
