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
      (invocation) async =>
          (invocation.positionalArguments.single as WalletInfo).id == "a" ? 10 : 20,
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
    await bloc.stream.firstWhere((state) => state.config.totalSize != null);
    return bloc;
  }

  Future<AppBackupState> next(AppBackupBloc bloc) => bloc.stream.first;

  Future<List<AppBackupState>> statesUntil(
    AppBackupBloc bloc,
    bool Function(AppBackupState state) done,
  ) async {
    final states = <AppBackupState>[];
    await for (final state in bloc.stream) {
      states.add(state);
      if (done(state)) break;
    }
    return states;
  }

  Future<T> presented<T extends AppBackupPresentation>(AppBackupBloc bloc) async =>
      await bloc.presentation.firstWhere((event) => event is T) as T;

  void stubSave(AppBackupStorage storage, bool saved) =>
      when(() => storageService.save(backupFile, storage)).thenAnswer((_) async => saved);

  Future<AppBackupBloc> verifiedBloc() async {
    final bloc = await loadedBloc();
    bloc.add(VerificationChanged("Cat1-Dog2"));
    await next(bloc);
    return bloc;
  }

  test("loads wallets, saved exclusions, password and sizes", () async {
    final bloc = await loadedBloc();

    expect(bloc.state, isA<AppBackupIdle>());
    expect(bloc.state.config.password, "Cat1-Dog2");
    expect(bloc.state.config.isSelected(walletA), isTrue);
    expect(bloc.state.config.isSelected(walletB), isFalse);
    expect(bloc.state.config.totalSize, 110);
    expect(bloc.state.config.preferredStorage, AppBackupStorage.cloud);
    await bloc.close();
  });

  test("selection changes update the config and are saved", () async {
    final bloc = await loadedBloc();

    bloc.add(WalletToggled("b"));
    final toggled = await next(bloc);
    expect(toggled.config.excludedWalletIds, isEmpty);
    expect(toggled.config.totalSize, 130);
    verify(() => preferences.setExcludedWalletIds(<String>{})).called(1);

    bloc.add(AllWalletsDeselected());
    final deselected = await next(bloc);
    expect(deselected.config.canContinue, isFalse);
    expect(deselected.config.selectedCount, 0);
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
    expect((await next(bloc)).config.canContinue, isTrue);
    await bloc.close();
  });

  test("typing starts verification and the mismatch only shows after submitting", () async {
    final bloc = await loadedBloc();

    bloc.add(VerificationChanged("Cat1-Dog3"));
    final typed = await next(bloc) as AppBackupVerifying;
    expect(typed.showMismatch, isFalse);

    bloc.add(VerificationSubmitted());
    final submitted = await next(bloc) as AppBackupVerifying;
    expect(submitted.showMismatch, isTrue);
    expect(submitted.canSubmit, isFalse);

    bloc.add(VerificationChanged("Cat1-Dog2"));
    final corrected = await next(bloc) as AppBackupVerifying;
    expect(corrected.showMismatch, isFalse);
    expect(corrected.passwordMatches, isTrue);
    await bloc.close();
  });

  test("setup creates the backup, waits for a storage and completes once saved", () async {
    final bloc = await verifiedBloc();

    final created = presented<BackupCreated>(bloc);
    bloc.add(VerificationSubmitted());
    final creating = await statesUntil(bloc, (state) => state is AppBackupReadyToSave);
    await created;
    expect(creating.map((state) => state.runtimeType), [AppBackupCreating, AppBackupReadyToSave]);
    expect((bloc.state as AppBackupReadyToSave).file, backupFile);
    verify(
      () => backupService.exportBackupFile(
        "Cat1-Dog2",
        excludedWalletIds: {"b"},
        outputPath: backupFile.path,
      ),
    ).called(1);

    stubSave(AppBackupStorage.custom, false);
    bloc.add(SaveRequested(AppBackupStorage.custom));
    final cancelled = await statesUntil(bloc, (state) => state is AppBackupReadyToSave);
    expect(cancelled.first, isA<AppBackupSaving>());
    expect((bloc.state as AppBackupReadyToSave).file, backupFile);
    expect(backupFile.existsSync(), isTrue);
    verifyNever(() => preferences.completeSetup());

    stubSave(AppBackupStorage.custom, true);
    final savedEvent = presented<BackupSaved>(bloc);
    bloc.add(SaveRequested(AppBackupStorage.custom));
    expect((await savedEvent).isFirstBackup, isTrue);
    expect(bloc.state, isA<AppBackupIdle>());
    expect(bloc.state.config.isSetupCompleted, isTrue);
    expect(bloc.state.config.preferredStorage, AppBackupStorage.custom);
    expect(bloc.state.config.lastBackup, isNotNull);
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

    final regeneratedEvent = presented<PasswordRegenerated>(bloc);
    bloc.add(PasswordRegenerationRequested());
    final regenerated = await next(bloc) as AppBackupVerifying;
    await regeneratedEvent;
    final newPassword = regenerated.newPassword!;
    expect(newPassword, matches(RegExp(r"^([A-Z][a-z]+[0-9]-){7}[A-Z][a-z]+[0-9]$")));
    expect(regenerated.config.password, "Cat1-Dog2");
    expect(regenerated.passwordToVerify, newPassword);
    expect(regenerated.input, isEmpty);

    bloc.add(VerificationChanged("Cat1-Dog2"));
    await next(bloc);
    bloc.add(VerificationSubmitted());
    expect((await next(bloc) as AppBackupVerifying).showMismatch, isTrue);
    verifyNever(() => secureStorage.write(key: key, value: any(named: "value")));

    bloc.add(VerificationChanged(newPassword));
    await next(bloc);
    final savedEvent = presented<PasswordSaved>(bloc);
    bloc.add(VerificationSubmitted());
    final saved = await next(bloc);
    await savedEvent;
    expect(saved, isA<AppBackupIdle>());
    expect(saved.config.password, newPassword);
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

  test("a failed export is presented and goes back to verification", () async {
    when(
      () => backupService.exportBackupFile(
        any(),
        excludedWalletIds: any(named: "excludedWalletIds"),
        outputPath: any(named: "outputPath"),
      ),
    ).thenThrow(StateError("disk full"));
    final bloc = await verifiedBloc();

    final failed = presented<BackupFailed>(bloc);
    bloc.add(VerificationSubmitted());
    expect((await failed).error, contains("disk full"));
    final verifying = bloc.state as AppBackupVerifying;
    expect(verifying.input, "Cat1-Dog2");
    expect(verifying.canSubmit, isTrue);
    await bloc.close();
  });

  test("backup now saves straight to the preferred storage", () async {
    when(() => preferences.isSetupCompleted).thenReturn(true);
    when(() => preferences.preferredStorage).thenReturn(AppBackupStorage.custom);
    stubSave(AppBackupStorage.custom, true);
    final bloc = await loadedBloc();

    final states = <AppBackupState>[];
    final subscription = bloc.stream.listen(states.add);
    final saved = presented<BackupSaved>(bloc);
    final created = bloc.presentation.where((event) => event is BackupCreated).toList();
    bloc.add(BackupNowRequested());
    expect((await saved).isFirstBackup, isFalse);
    await subscription.cancel();
    expect(states.map((state) => state.runtimeType),
        [AppBackupCreating, AppBackupSaving, AppBackupIdle]);
    await bloc.close();
    expect(await created, isEmpty);
    verify(() => storageService.save(backupFile, AppBackupStorage.custom)).called(1);
    expect(backupFile.existsSync(), isFalse);
  });

  test("a backup handed to another app keeps its file after saving", () async {
    when(() => preferences.isSetupCompleted).thenReturn(true);
    when(() => preferences.preferredStorage).thenReturn(AppBackupStorage.cloud);
    when(() => storageService.keepsFileAfterSave(AppBackupStorage.cloud)).thenReturn(true);
    stubSave(AppBackupStorage.cloud, true);
    final bloc = await loadedBloc();

    final saved = presented<BackupSaved>(bloc);
    bloc.add(BackupNowRequested());
    await saved;
    expect(backupFile.existsSync(), isTrue);
    await bloc.close();
    expect(backupFile.existsSync(), isTrue);
  });

  test("a cancelled backup now deletes the file and goes back to idle", () async {
    when(() => preferences.isSetupCompleted).thenReturn(true);
    stubSave(AppBackupStorage.cloud, false);
    final bloc = await loadedBloc();

    bloc.add(BackupNowRequested());
    final states = await statesUntil(bloc, (state) => state is AppBackupIdle);
    expect(states.map((state) => state.runtimeType),
        [AppBackupCreating, AppBackupSaving, AppBackupIdle]);
    expect(backupFile.existsSync(), isFalse);
    verifyNever(() => preferences.recordBackup(any()));
    await bloc.close();
  });
}
