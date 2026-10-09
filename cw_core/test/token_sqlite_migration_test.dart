import "dart:io";

import "package:cw_core/cake_hive.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/erc20_token.dart" as erc20_sql;
import "package:cw_core/erc20_token_legacy.dart" as erc20_legacy;
import "package:cw_core/node.dart";
import "package:cw_core/root_dir.dart";
import "package:cw_core/spl_token.dart" as spl_sql;
import "package:cw_core/spl_token_legacy.dart" as spl_legacy;
import "package:cw_core/tron_token.dart" as tron_sql;
import "package:cw_core/tron_token_legacy.dart" as tron_legacy;
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

// Faking the documents dir keeps getAppDir() off the platform channel, so the
// test runs with a plain `flutter test` on any host and in CI.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

Future<void> main() async {
  final dataRoot = Directory("./test/data/token_migration");

  Future<void> insertWalletInfoRow(String name, WalletType type) async {
    await db!.insert("WalletInfo", {
      "id": "${walletTypeToString(type).toLowerCase()}_$name",
      "name": name,
      "type": type.index,
      "isRecovery": 0,
      "restoreHeight": 0,
      "timestamp": 0,
      "dirPath": "",
      "path": "",
      "address": "",
      "showIntroCakePayCard": 0,
      "walletInfoDerivationInfoId": 0,
      "isNonSeedWallet": 0,
      "sortOrder": 0,
      "receiveInfoboxDismissed": 0,
      "showCombinedBalance": 1,
    });
  }

  group(
    "token sqlite migration",
    () {
      setUpAll(() async {
        if (dataRoot.existsSync()) {
          dataRoot.deleteSync(recursive: true);
        }
        dataRoot.createSync(recursive: true);

        PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);

        // On linux getAppDir() appends /cake_wallet to the documents dir and picks the
        // first existing candidate, so create it up front to keep CI on the faked path.
        Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);

        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        await initDb();

        // Everything must share the dir initDb resolved so boxExists finds the boxes
        final appDir = await getAppDir();
        CakeHive.init(appDir.path);

        if (!CakeHive.isAdapterRegistered(erc20_legacy.Erc20Token.typeId)) {
          CakeHive.registerAdapter(erc20_legacy.Erc20TokenAdapter());
        }
        if (!CakeHive.isAdapterRegistered(spl_legacy.SPLToken.typeId)) {
          CakeHive.registerAdapter(spl_legacy.SPLTokenAdapter());
        }
        if (!CakeHive.isAdapterRegistered(tron_legacy.TronToken.typeId)) {
          CakeHive.registerAdapter(tron_legacy.TronTokenAdapter());
        }

        // Two ethereum wallets whose names sanitize to the same box name, plus sol and tron
        await insertWalletInfoRow("My Wallet", WalletType.ethereum);
        await insertWalletInfoRow("My_Wallet", WalletType.ethereum);
        await insertWalletInfoRow("sol wallet", WalletType.solana);
        await insertWalletInfoRow("tron1", WalletType.tron);

        // Legacy global box shared by every ethereum wallet in the pre per-wallet era
        final globalBox = await CakeHive.openBox<erc20_legacy.Erc20Token>("Erc20Tokens");
        await globalBox.put(
          "0xGlobalTokenAAA",
          erc20_legacy.Erc20Token(
            name: "Global Legacy",
            symbol: "GLB",
            contractAddress: "0xGlobalTokenAAA",
            decimal: 18,
            enabled: true,
          ),
        );

        // Per-wallet ethereum box with a duplicate contract in two casings and a disabled token
        final ethBox =
            await CakeHive.openBox<erc20_legacy.Erc20Token>("My_Wallet_EthereumErc20Tokens");
        await ethBox.put(
          "0xDupCASE01",
          erc20_legacy.Erc20Token(
            name: "Dup Token",
            symbol: "DUP",
            contractAddress: "0xDupCASE01",
            decimal: 18,
            enabled: false,
            iconPath: "",
          ),
        );
        await ethBox.put(
          "0xdupcase01",
          erc20_legacy.Erc20Token(
            name: "Dup Token",
            symbol: "DUP",
            contractAddress: "0xdupcase01",
            decimal: 18,
            enabled: true,
            iconPath: "assets/images/dup.png",
          ),
        );
        await ethBox.put(
          "0xkeepmedisabled",
          erc20_legacy.Erc20Token(
            name: "Keep Me",
            symbol: "KEEP",
            contractAddress: "0xkeepmedisabled",
            decimal: 6,
            enabled: false,
          ),
        );

        // A polygon chain box for the same wallet name
        final polyBox =
            await CakeHive.openBox<erc20_legacy.Erc20Token>("My_Wallet_PolygonErc20Tokens");
        await polyBox.put(
          "0xpolytoken01",
          erc20_legacy.Erc20Token(
            name: "Poly Token",
            symbol: "PLY",
            contractAddress: "0xpolytoken01",
            decimal: 18,
            enabled: true,
            tag: "POL",
          ),
        );

        // SPL and Tron boxes, base58 keys must keep their exact casing
        final splBox = await CakeHive.openBox<spl_legacy.SPLToken>("sol_wallet_SPLTokens");
        await splBox.put(
          "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
          spl_legacy.SPLToken(
            name: "USD Coin",
            symbol: "USDC",
            mintAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            decimal: 6,
            mint: "usdc",
            enabled: false,
          ),
        );

        final tronBox = await CakeHive.openBox<tron_legacy.TronToken>("tron1_TronTokens");
        await tronBox.put(
          "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
          tron_legacy.TronToken(
            name: "Tether USD",
            symbol: "USDT",
            contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            decimal: 6,
            enabled: true,
          ),
        );

        await globalBox.close();
        await ethBox.close();
        await polyBox.close();
        await splBox.close();
        await tronBox.close();
      });

      tearDownAll(() async {
        await db?.close();
        db = null;
        if (dataRoot.existsSync()) {
          dataRoot.deleteSync(recursive: true);
        }
      });

      test("migrates every token box into sqlite", () async {
        await erc20_legacy.performErc20TokenHiveMigration();
        await spl_legacy.performSplTokenHiveMigration();
        await tron_legacy.performTronTokenHiveMigration();

        // Both ethereum wallets share the sanitized box name, so each gets the rows
        for (final walletName in ["My Wallet", "My_Wallet"]) {
          final ethTokens = await erc20_sql.Erc20Token.getAllForWallet(walletName, 1);
          final addresses = ethTokens.map((t) => t.contractAddress).toSet();

          expect(
            addresses,
            {"0xglobaltokenaaa", "0xdupcase01", "0xkeepmedisabled"},
            reason: "wallet $walletName should have the global, merged dup and disabled tokens",
          );

          final dup = ethTokens.firstWhere((t) => t.contractAddress == "0xdupcase01");
          expect(dup.enabled, true, reason: "dup merge ORs the enabled flags");
          expect(dup.iconPath, "assets/images/dup.png", reason: "dup merge prefers non-empty icon");

          final keep = ethTokens.firstWhere((t) => t.contractAddress == "0xkeepmedisabled");
          expect(keep.enabled, false, reason: "disabled toggle must survive the migration");

          final polyTokens = await erc20_sql.Erc20Token.getAllForWallet(walletName, 137);
          expect(polyTokens.map((t) => t.contractAddress), ["0xpolytoken01"]);
        }

        final splTokens = await spl_sql.SPLToken.getAllForWallet("sol wallet");
        expect(splTokens.length, 1);
        expect(
          splTokens.first.mintAddress,
          "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
          reason: "mint address casing must be preserved",
        );
        expect(splTokens.first.enabled, false);

        final tronTokens = await tron_sql.TronToken.getAllForWallet("tron1");
        expect(tronTokens.length, 1);
        expect(
          tronTokens.first.contractAddress,
          "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
          reason: "tron contract address casing must be preserved",
        );

        // Drained boxes are removed from disk
        expect(await CakeHive.boxExists("Erc20Tokens"), false);
        expect(await CakeHive.boxExists("My_Wallet_EthereumErc20Tokens"), false);
        expect(await CakeHive.boxExists("My_Wallet_PolygonErc20Tokens"), false);
        expect(await CakeHive.boxExists("sol_wallet_SPLTokens"), false);
        expect(await CakeHive.boxExists("tron1_TronTokens"), false);
      });

      test("re-running the migrations is a no-op", () async {
        final before = (await erc20_sql.Erc20Token.selectList("", [])).length +
            (await spl_sql.SPLToken.selectList("", [])).length +
            (await tron_sql.TronToken.selectList("", [])).length;

        await erc20_legacy.performErc20TokenHiveMigration();
        await spl_legacy.performSplTokenHiveMigration();
        await tron_legacy.performTronTokenHiveMigration();

        final after = (await erc20_sql.Erc20Token.selectList("", [])).length +
            (await spl_sql.SPLToken.selectList("", [])).length +
            (await tron_sql.TronToken.selectList("", [])).length;

        expect(after, before);
      });

      test("an interrupted migration re-drains over existing rows without duplicating", () async {
        // Simulates a run that inserted rows into sqlite but died before the box was
        // emptied: the box reappears holding a token that already has a row (USDC,
        // re-enabled in the box copy) plus one the interrupted run never reached (BONK)
        final box = await CakeHive.openBox<spl_legacy.SPLToken>("sol_wallet_SPLTokens");
        await box.put(
          "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
          spl_legacy.SPLToken(
            name: "USD Coin",
            symbol: "USDC",
            mintAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            decimal: 6,
            mint: "usdc",
            enabled: true,
          ),
        );
        await box.put(
          "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
          spl_legacy.SPLToken(
            name: "Bonk",
            symbol: "BONK",
            mintAddress: "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
            decimal: 5,
            mint: "bonk",
            enabled: true,
          ),
        );
        await box.close();

        await spl_legacy.performSplTokenHiveMigration();

        final tokens = await spl_sql.SPLToken.getAllForWallet("sol wallet");
        expect(tokens.length, 2, reason: "the re-drain must not duplicate the existing USDC row");

        final usdc = tokens.firstWhere((t) => t.symbol == "USDC");
        expect(usdc.enabled, true, reason: "the box copy wins over the stale row on re-drain");

        expect(await CakeHive.boxExists("sol_wallet_SPLTokens"), false);
      });

      test("save without wallet context throws", () {
        final token = erc20_sql.Erc20Token(
          name: "No Context",
          symbol: "NOC",
          contractAddress: "0xnocontext",
          decimal: 18,
        );

        expect(token.save, throwsStateError);
      });

      test("seeding preserves the enabled toggle without clobbering", () async {
        // Same shape addInitialTokens uses: read existing, copyWith preserving enabled
        final existing =
            await erc20_sql.Erc20Token.getByContract("My Wallet", 1, "0xKEEPMEDISABLED");
        expect(existing, isNotNull);
        expect(existing!.enabled, false);

        final refreshedDefault = erc20_sql.Erc20Token(
          name: "Keep Me Renamed By Defaults",
          symbol: "KEEP",
          contractAddress: "0xkeepmedisabled",
          decimal: 6,
          enabled: true,
        );
        final toSave = erc20_sql.Erc20Token.copyWith(
          refreshedDefault,
          enabled: existing.enabled,
          walletName: "My Wallet",
          chainId: 1,
        );
        await toSave.save();

        final reloaded =
            await erc20_sql.Erc20Token.getByContract("My Wallet", 1, "0xkeepmedisabled");
        expect(reloaded!.enabled, false, reason: "metadata refresh must not re-enable the token");
        expect(reloaded.name, "Keep Me Renamed By Defaults");

        final rowCount = (await erc20_sql.Erc20Token.getAllForWallet("My Wallet", 1)).length;
        expect(rowCount, 3, reason: "upsert must replace, not duplicate");
      });

      test("rename moves rows and delete removes them", () async {
        await erc20_sql.Erc20Token.renameWallet("My Wallet", "Renamed Wallet");

        expect(await erc20_sql.Erc20Token.getAllForWallet("My Wallet", 1), isEmpty);
        expect((await erc20_sql.Erc20Token.getAllForWallet("Renamed Wallet", 1)).length, 3);
        expect((await erc20_sql.Erc20Token.getAllForWallet("Renamed Wallet", 137)).length, 1);

        await erc20_sql.Erc20Token.deleteAllForWallet("My_Wallet");
        expect(await erc20_sql.Erc20Token.getAllForWallet("My_Wallet", 1), isEmpty);
        expect(await erc20_sql.Erc20Token.getAllForWallet("My_Wallet", 137), isEmpty);

        // Rename into a name that has orphaned rows must not trip the unique index
        await erc20_sql.Erc20Token.renameWallet("Renamed Wallet", "My_Wallet");
        expect((await erc20_sql.Erc20Token.getAllForWallet("My_Wallet", 1)).length, 3);
      });
    },
  );

  group(
    "sqlite v15 migration",
    () {
      final v14Root = Directory("./test/data/sqlite_v15_migration");

      setUpAll(() async {
        if (v14Root.existsSync()) {
          v14Root.deleteSync(recursive: true);
        }
        v14Root.createSync(recursive: true);
        Directory("${v14Root.path}/cake_wallet").createSync(recursive: true);

        PathProviderPlatform.instance = _FakePathProviderPlatform(v14Root.absolute.path);
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;

        // The two tables the v15 step alters, in their v14 shape
        final v14 = await databaseFactoryFfi.openDatabase(
          "${(await getAppDir()).path}/cake.db",
          options: OpenDatabaseOptions(
            version: 14,
            onCreate: (db, version) async {
              await db.execute("""
CREATE TABLE WalletInfo (
  walletInfoId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  id TEXT NOT NULL,
  name TEXT NOT NULL,
  "type" INTEGER NOT NULL,
  isRecovery INTEGER DEFAULT (0) NOT NULL,
  walletInfoDerivationInfoId INTEGER NOT NULL,
  restoreHeight INTEGER DEFAULT (0) NOT NULL,
  "timestamp" INTEGER DEFAULT (0) NOT NULL,
  dirPath TEXT NOT NULL,
  "path" TEXT NOT NULL,
  address TEXT NOT NULL,
  yatEid TEXT,
  yatLastUsedAddressRaw TEXT,
  showIntroCakePayCard INTEGER DEFAULT (1),
  addressPageType TEXT,
  network TEXT,
  hardwareWalletType INTEGER,
  parentAddress TEXT,
  hashedWalletIdentifier TEXT,
  isNonSeedWallet INTEGER DEFAULT (0) NOT NULL,
  sortOrder INTEGER DEFAULT (0) NOT NULL,
  receiveInfoboxDismissed BOOLEAN DEFAULT FALSE,
  showCombinedBalance BOOLEAN DEFAULT TRUE,
  favoriteTokenAddress TEXT DEFAULT NULL,
  showSeedBackupReminder BOOLEAN DEFAULT FALSE
);
""");
              await db.execute("""
CREATE TABLE Node (
NodeId INTEGER PRIMARY KEY,
uri TEXT NOT NULL,
path TEXT,
login TEXT,
label TEXT,
password TEXT,
isPow INTEGER NOT NULL,
useSSL INTEGER,
typeRaw INTEGER NOT NULL,
trusted INTEGER NOT NULL,
socksProxyAddress TEXT,
isEnabledForAutoSwitching BOOLEAN DEFAULT FALSE,
isOfficial BOOLEAN DEFAULT FALSE,
isBuiltin BOOLEAN DEFAULT FALSE,
isDefault BOOLEAN DEFAULT FALSE
);
""");
            },
          ),
        );

        await v14.insert("WalletInfo", {
          "id": "ethereum_Upgrade Wallet",
          "name": "Upgrade Wallet",
          "type": WalletType.ethereum.index,
          "isRecovery": 1,
          "restoreHeight": 17,
          "timestamp": 1700000000000,
          "dirPath": "/wallets/ethereum/Upgrade Wallet",
          "path": "/wallets/ethereum/Upgrade Wallet/Upgrade Wallet",
          "address": "0x52908400098527886E0F7030069857D2E4169EE7",
          "showIntroCakePayCard": 0,
          "walletInfoDerivationInfoId": 3,
          "isNonSeedWallet": 0,
          "sortOrder": 2,
          "receiveInfoboxDismissed": 1,
          "showCombinedBalance": 0,
          "favoriteTokenAddress": "0xdac17f958d2ee523a2206206994597c13d831ec7",
        });

        await v14.insert("Node", {
          "NodeId": 41,
          "uri": "ethereum-rpc.publicnode.com",
          "path": "",
          "label": "Public Node",
          "isPow": 0,
          "useSSL": 1,
          "typeRaw": serializeToInt(WalletType.ethereum),
          "trusted": 0,
          "isBuiltin": 1,
          "isDefault": 1,
        });

        await v14.close();

        await initDb();
      });

      tearDownAll(() async {
        await db?.close();
        db = null;
        if (v14Root.existsSync()) {
          v14Root.deleteSync(recursive: true);
        }
      });

      test("upgrades to version 15 with the EvmNetwork table", () async {
        final version = await db!.rawQuery("PRAGMA user_version");
        expect(version.single.values.single, 15);

        final tables = await db!.rawQuery(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'EvmNetwork'");
        expect(tables, hasLength(1));

        for (final table in ["WalletInfo", "Node"]) {
          final columns = await db!.rawQuery("PRAGMA table_info($table)");
          expect(columns.map((column) => column["name"]), contains("chainId"), reason: table);
        }
      });

      test("existing wallet rows read back unchanged with no chain ID", () async {
        final info = (await WalletInfo.getAll()).single;

        expect(info.chainId, isNull);
        expect(info.name, "Upgrade Wallet");
        expect(info.type, WalletType.ethereum);
        expect(info.isRecovery, isTrue);
        expect(info.restoreHeight, 17);
        expect(info.address, "0x52908400098527886E0F7030069857D2E4169EE7");
        expect(info.derivationInfoId, 3);
        expect(info.sortOrder, 2);
        expect(info.receiveInfoboxDismissed, isTrue);
        expect(info.showCombinedBalance, isFalse);
        expect(info.favoriteTokenAddress, "0xdac17f958d2ee523a2206206994597c13d831ec7");
      });

      test("existing node rows read back unchanged and equal a node built from the list", () async {
        final stored = (await Node.getAll()).single;

        expect(stored.chainId, isNull);
        expect(stored.id, 41);
        expect(stored.uriRaw, "ethereum-rpc.publicnode.com");
        expect(stored.type, WalletType.ethereum);
        expect(stored.isBuiltin, isTrue);
        expect(stored.isDefault, isTrue);

        final fromList = Node(
          uri: "ethereum-rpc.publicnode.com",
          type: WalletType.ethereum,
          label: "Public Node",
          useSSL: true,
          path: "",
        );
        expect(fromList, stored);
        expect(fromList.hashCode, stored.hashCode);

        // Node equality ignores the chain ID, so validateBuiltinNodes neither deletes nor re-adds
        fromList.chainId = 10;
        expect(fromList, stored);
      });
    },
  );
}
