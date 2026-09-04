import "dart:io";

import "package:cw_core/db/sqlite.dart";
import "package:cw_core/imported_nft.dart";
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
  final dataRoot = Directory("./test/data/imported_nft");

  Future<void> insert(String walletName, String chain, String identifier) =>
      ImportedNFT(walletName: walletName, chain: chain, identifier: identifier, name: identifier)
          .save();

  Future<List<String>> identifiersFor(String walletName, [String? chain]) async =>
      (await ImportedNFT.getAllForWallet(walletName, chain)).map((nft) => nft.identifier).toList();

  setUpAll(() async {
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
    await db!.delete(ImportedNFT.tableName);
  });

  tearDownAll(() {
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });

  group("ImportedNFT wallet lifecycle", () {
    test("reading without a chain returns every chain the wallet imported on", () async {
      await insert("Main", ImportedNFT.solanaChain, "SolMint");
      await insert("Main", "eth", "0xcontract:1");
      await insert("Main", "polygon", "0xother:7");

      expect(await identifiersFor("Main", "eth"), ["0xcontract:1"]);
      expect(
        (await identifiersFor("Main"))..sort(),
        ["0xcontract:1", "0xother:7", "SolMint"],
      );
    });

    test("rename moves every chain and leaves other wallets alone", () async {
      await insert("Main", ImportedNFT.solanaChain, "SolMint");
      await insert("Main", "eth", "0xcontract:1");
      await insert("Sidekick", "eth", "0xkeep:9");

      await ImportedNFT.renameWallet("Main", "Renamed");

      expect(await identifiersFor("Main"), isEmpty);
      expect((await identifiersFor("Renamed"))..sort(), ["0xcontract:1", "SolMint"]);
      expect(await identifiersFor("Sidekick"), ["0xkeep:9"]);
    });

    test("renaming into a name that still has orphan rows does not trip the unique index",
        () async {
      await insert("Orphaned", "eth", "0xcontract:1");
      await insert("Orphaned", "polygon", "0xsurvivor:5");
      await insert("Main", "eth", "0xcontract:1");
      await insert("Main", "eth", "0xsecond:2");

      await ImportedNFT.renameWallet("Main", "Orphaned", chains: const ["eth"]);

      // Only the colliding chain is cleared. A row the destination holds on
      // another chain is not ours to delete.
      expect(
        (await identifiersFor("Orphaned"))..sort(),
        ["0xcontract:1", "0xsecond:2", "0xsurvivor:5"],
      );
    });

    test("renaming a solana wallet leaves a same-named evm wallet's NFTs alone", () async {
      await insert("Sol", ImportedNFT.solanaChain, "SolMint");
      await insert("Vault", "eth", "0xEthNFT:1");

      await ImportedNFT.renameWallet(
        "Sol",
        "Vault",
        chains: const [ImportedNFT.solanaChain],
      );

      expect((await identifiersFor("Vault"))..sort(), ["0xEthNFT:1", "SolMint"]);
    });

    test("deleting a solana wallet leaves a same-named evm wallet's NFTs alone", () async {
      await insert("Vault", ImportedNFT.solanaChain, "SolMint");
      await insert("Vault", "eth", "0xEthNFT:1");

      await ImportedNFT.deleteAllForWallet(
        "Vault",
        chains: const [ImportedNFT.solanaChain],
      );

      expect(await identifiersFor("Vault"), ["0xEthNFT:1"]);
    });

    test("an empty chain scope deletes nothing rather than everything", () async {
      await insert("Main", "eth", "0xcontract:1");

      await ImportedNFT.deleteAllForWallet("Main", chains: const []);

      expect(await identifiersFor("Main"), ["0xcontract:1"]);
    });

    test("delete removes every chain for that wallet only", () async {
      await insert("Main", ImportedNFT.solanaChain, "SolMint");
      await insert("Main", "eth", "0xcontract:1");
      await insert("Sidekick", ImportedNFT.solanaChain, "OtherMint");

      await ImportedNFT.deleteAllForWallet("Main");

      expect(await identifiersFor("Main"), isEmpty);
      expect(await identifiersFor("Sidekick"), ["OtherMint"]);
    });

    test("deleting one leaves the wallet's other imports in place", () async {
      await insert("Main", "eth", "0xcontract:1");
      await insert("Main", "eth", "0xsecond:2");
      await insert("Main", "polygon", "0xcontract:1");

      await ImportedNFT.deleteOne("Main", "eth", "0xcontract:1");

      expect(await identifiersFor("Main", "eth"), ["0xsecond:2"]);
      expect(await identifiersFor("Main", "polygon"), ["0xcontract:1"]);
    });

    test("copying to a new name keeps the rows under the old one", () async {
      await insert("Main", ImportedNFT.solanaChain, "SolMint");
      await insert("Main", "eth", "0xcontract:1");

      for (final nft in await ImportedNFT.getAllForWallet("Main")) {
        await ImportedNFT.copyWith(nft, walletName: "Copy").save();
      }

      expect((await identifiersFor("Main"))..sort(), ["0xcontract:1", "SolMint"]);
      expect((await identifiersFor("Copy"))..sort(), ["0xcontract:1", "SolMint"]);
    });

    test("a copy is a new row, so saving it does not overwrite the original", () async {
      await insert("Main", "eth", "0xcontract:1");

      final original = (await ImportedNFT.getAllForWallet("Main")).single;
      final copy = ImportedNFT.copyWith(original, walletName: "Copy");
      await copy.save();

      expect(copy.id, isNot(original.id));
      expect((await ImportedNFT.getAllForWallet("Main")).single.id, original.id);
    });
  });
}
