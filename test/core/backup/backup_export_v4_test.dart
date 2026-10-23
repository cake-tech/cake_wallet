import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:archive/archive_io.dart";
import "package:cake_backup/backup.dart" as cake_backup;
import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cake_wallet/core/key_service.dart";
import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/entities/transaction_description.dart";
import "package:cw_core/cake_hive.dart";
import "package:cw_core/db/sqlite.dart" as sqlite;
import "package:cw_core/unspent_coins_info.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mocktail/mocktail.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:plugin_platform_interface/plugin_platform_interface.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockKeyService extends Mock implements KeyService {}

class _MockTransactionDescriptionBox extends Mock implements Box<TransactionDescription> {}

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.documents, this.temporary);

  final String documents;
  final String temporary;

  @override
  Future<String?> getApplicationDocumentsPath() async => documents;

  @override
  Future<String?> getTemporaryPath() async => temporary;
}

void main() {
  late Directory root;
  late Directory appDir;
  late Box<UnspentCoinsInfo> unspent;
  late BackupServiceV3 service;

  const password = "backup-password";

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    root = Directory.systemTemp.createTempSync("backup_export_v4_test");
    appDir = Directory("${root.path}/documents")..createSync();
    PathProviderPlatform.instance = _FakePathProvider(appDir.path, "${root.path}/tmp");
    PackageInfo.setMockInitialValues(
      appName: "Cake Wallet",
      packageName: "test",
      version: "1.0.0",
      buildNumber: "1",
      buildSignature: "",
    );

    await sqlite.initDb();
    for (final name in ["Kept", "Dropped"]) {
      await WalletInfo.external(
        id: "WalletType.bitcoin_$name",
        name: name,
        type: WalletType.bitcoin,
        isRecovery: false,
        restoreHeight: 0,
        date: DateTime(2026),
        dirPath: "",
        path: "",
        address: "address-$name",
      ).save();
      final dir = Directory("${appDir.path}/wallets/bitcoin/$name")..createSync(recursive: true);
      File("${dir.path}/$name").writeAsStringSync("wallet file $name");
    }
    File("${appDir.path}/contacts.hive").writeAsBytesSync([1, 2, 3]);
    File("${appDir.path}/unrelated_leftover.zip").writeAsBytesSync([9, 9, 9]);

    CakeHive.init(appDir.path);
    if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
      CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
    }
    unspent = await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
    for (final name in ["Kept", "Dropped"]) {
      await unspent.add(
        UnspentCoinsInfo(
          walletId: "WalletType.bitcoin_$name",
          hash: "hash-$name",
          isFrozen: false,
          isSending: true,
          noteRaw: null,
          address: "address-$name",
          vout: 0,
          value: 1,
        ),
      );
    }

    SharedPreferences.setMockInitialValues({
      PreferencesKey.currentWalletName: "Dropped",
      PreferencesKey.currentWalletType: serializeToInt(WalletType.bitcoin),
      PreferencesKey.appBackupLastTimestamp: 1,
    });

    final secureStorage = _MockSecureStorage();
    when(() => secureStorage.read(key: any(named: "key"))).thenAnswer((_) async => password);
    when(() => secureStorage.readAll()).thenAnswer(
      (_) async => {
        "MONERO_WALLET_PASSWORD_KEPT": "kept-password",
        "MONERO_WALLET_PASSWORD_DROPPED": "dropped-password",
        "OTHER_SETTING": "kept",
      },
    );
    final keyService = _MockKeyService();
    when(() => keyService.getWalletPassword(walletName: any(named: "walletName")))
        .thenAnswer((invocation) async => "${invocation.namedArguments[#walletName]}-password");
    final transactionDescriptions = _MockTransactionDescriptionBox();
    when(() => transactionDescriptions.toMap()).thenReturn({});

    service = BackupServiceV3(
      secureStorage,
      transactionDescriptions,
      keyService,
      await SharedPreferences.getInstance(),
      unspentCoinsInfoBox: unspent,
    );
  });

  tearDown(() async {
    await CakeHive.close();
    await sqlite.db?.close();
    sqlite.db = null;
    root.deleteSync(recursive: true);
  });

  Future<Archive> decryptInnerArchive(File backup) async {
    final outer = ZipDecoder().decodeBytes(backup.readAsBytesSync());
    final metadata = BackupMetadata.fromJson(
      json.decode(utf8.decode(outer.findFile("metadata.json")!.content as List<int>))
          as Map<String, dynamic>,
    );
    expect(metadata.version, BackupVersion.v4);

    final data = Uint8List.fromList(outer.findFile("data.bin")!.content as List<int>);
    final plain = BytesBuilder();
    var offset = 0;
    for (final chunk in metadata.chunks) {
      plain.add(
        await cake_backup.decrypt(
          password,
          Uint8List.sublistView(data, offset, offset + chunk.length.encrypted),
        ),
      );
      offset += chunk.length.encrypted;
    }
    return ZipDecoder().decodeBytes(plain.toBytes());
  }

  test("v4 export only contains the selected wallets' data", () async {
    final backup = await service.exportBackupFileV4(
      password,
      excludedWalletIds: {"WalletType.bitcoin_Dropped"},
      outputPath: "${root.path}/out/backup.zip",
    );

    final archive = await decryptInnerArchive(backup);
    final names = archive.files.where((file) => file.isFile).map((file) => file.name).toSet();

    expect(names, contains("wallets/bitcoin/Kept/Kept"));
    expect(names.where((name) => name.contains("Dropped")), isEmpty);
    expect(names, contains("contacts.hive"));
    expect(names, isNot(contains("unrelated_leftover.zip")));

    final dbCopy = File("${root.path}/restored.db")
      ..writeAsBytesSync(archive.findFile("cake.db")!.content as List<int>);
    final restoredDb = await databaseFactoryFfi.openDatabase(dbCopy.path);
    expect((await restoredDb.query("WalletInfo")).map((row) => row["name"]), ["Kept"]);
    await restoredDb.close();

    final keychain = json.decode(
      utf8.decode(
        await service.decryptV2(
          Uint8List.fromList(archive.findFile("~_keychain_dump")!.content as List<int>),
          "${secrets.backupKeychainSalt}$password",
        ),
      ),
    ) as Map<String, dynamic>;
    expect((keychain["wallets"] as List).map((wallet) => wallet["name"]), ["Kept"]);
    expect(
      keychain["_all"],
      {"MONERO_WALLET_PASSWORD_KEPT": "kept-password", "OTHER_SETTING": "kept"},
    );

    final preferences =
        json.decode(utf8.decode(archive.findFile("~_preferences_dump")!.content as List<int>))
            as Map<String, dynamic>;
    expect(preferences[PreferencesKey.currentWalletName], "Kept");
    expect(preferences.containsKey(PreferencesKey.appBackupLastTimestamp), isFalse);

    final hiveDir = Directory("${root.path}/hive_check")..createSync();
    File("${hiveDir.path}/check_unspent.hive")
        .writeAsBytesSync(archive.findFile("unspent.hive")!.content as List<int>);
    final restoredUnspent =
        await CakeHive.openBox<UnspentCoinsInfo>("check_unspent", path: hiveDir.path);
    expect(restoredUnspent.values.map((coin) => coin.walletId), ["WalletType.bitcoin_Kept"]);
    await restoredUnspent.close();

    expect(Directory("${appDir.path}/~_BACKUP_TMP").existsSync(), isFalse);
  });

  test("v4 export refuses an empty selection", () async {
    expect(
      () => service.exportBackupFileV4(
        password,
        excludedWalletIds: {"WalletType.bitcoin_Kept", "WalletType.bitcoin_Dropped"},
        outputPath: "${root.path}/out/backup.zip",
      ),
      throwsA(anything),
    );
  });
}
