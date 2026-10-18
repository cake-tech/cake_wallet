import "dart:io";

import "package:cake_wallet/entities/saved_nfts.dart";
import "package:cake_wallet/entities/solana_nft_asset_model.dart";
import "package:cake_wallet/entities/wallet_nft_response.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/imported_nft.dart";
import "package:flutter_test/flutter_test.dart";
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

SolanaNFTAssetModel solanaNFT(String mint, {String? name, bool? isOwned}) =>
    SolanaNFTAssetModel(mint: mint, address: mint, name: name ?? mint, isOwned: isOwned);

Future<void> main() async {
  final dataRoot = Directory("./test/data/saved_nfts");

  const wallet = "MyWallet";
  const otherWallet = "OtherWallet";
  const otherChain = "eth";

  final saved = SavedNFTs();

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

  group("SavedNFTs, solana", () {
    test("keeps what was added and reads it back", () async {
      await saved.addSolana(wallet, solanaNFT("MintA", name: "Ape", isOwned: true));

      final stored = await saved.solanaNFTs(wallet);

      expect(stored.keys, ["MintA"]);
      expect(stored["MintA"]!.name, "Ape");
      expect(stored["MintA"]!.isOwned, isTrue);
    });

    test("keeps wallets and chains apart", () async {
      await saved.addSolana(wallet, solanaNFT("MintA"));

      expect(await saved.solanaNFTs(otherWallet), isEmpty);
      expect(await saved.evmNFTs(wallet, otherChain), isEmpty);
    });

    test("adding the same mint twice replaces it rather than duplicating", () async {
      await saved.addSolana(wallet, solanaNFT("MintA", name: "first"));
      await saved.addSolana(wallet, solanaNFT("MintA", name: "second"));

      final stored = await saved.solanaNFTs(wallet);

      expect(stored.length, 1);
      expect(stored["MintA"]!.name, "second");
    });

    test("ignores an asset with no mint", () async {
      await saved.addSolana(wallet, SolanaNFTAssetModel(address: "x"));

      expect(await saved.solanaNFTs(wallet), isEmpty);
    });

    test("removes what was sent", () async {
      await saved.addSolana(wallet, solanaNFT("MintA"));
      await saved.removeSolana(wallet, "MintA");

      expect(await saved.solanaNFTs(wallet), isEmpty);
    });

    test("refresh updates what is still saved and does not add anything new", () async {
      await saved.addSolana(wallet, solanaNFT("MintA", name: "old", isOwned: true));

      await saved.refreshSolana(wallet, [
        solanaNFT("MintA", name: "new", isOwned: false),
        solanaNFT("MintB", name: "never imported"),
      ]);

      final stored = await saved.solanaNFTs(wallet);

      expect(stored.keys, ["MintA"]);
      expect(stored["MintA"]!.name, "new");
      expect(stored["MintA"]!.isOwned, isFalse);
    });

    // A refresh runs for seconds while it fetches metadata per mint, and the
    // user can import during it.
    test("an import that lands during a refresh is not lost", () async {
      await saved.addSolana(wallet, solanaNFT("MintA", name: "old"));

      final refreshing = saved.refreshSolana(wallet, [solanaNFT("MintA", name: "refreshed")]);
      final importing = saved.addSolana(wallet, solanaNFT("MintNew", name: "imported"));

      await Future.wait([refreshing, importing]);

      final stored = await saved.solanaNFTs(wallet);

      expect(stored.keys.toSet(), {"MintA", "MintNew"});
      expect(stored["MintA"]!.name, "refreshed");
    });

    test("an import during a refresh survives whichever order they run in", () async {
      await saved.addSolana(wallet, solanaNFT("MintA"));

      final importing = saved.addSolana(wallet, solanaNFT("MintNew"));
      final refreshing = saved.refreshSolana(wallet, [solanaNFT("MintA", name: "refreshed")]);

      await Future.wait([importing, refreshing]);

      expect((await saved.solanaNFTs(wallet)).keys.toSet(), {"MintA", "MintNew"});
    });

    test("an NFT sent during a refresh is not put back", () async {
      await saved.addSolana(wallet, solanaNFT("MintA"));

      final sending = saved.removeSolana(wallet, "MintA");
      final refreshing = saved.refreshSolana(wallet, [solanaNFT("MintA", name: "refreshed")]);

      await Future.wait([sending, refreshing]);

      expect(await saved.solanaNFTs(wallet), isEmpty);
    });

    test("an NFT sent after a refresh has already read the rows is not put back", () async {
      await saved.addSolana(wallet, solanaNFT("MintA"));

      // The refresh starts first here, so its read of the rows is queued ahead of
      // the delete. That is the ordering a real send hits: the user taps send
      // while a refresh is already in flight.
      final refreshing = saved.refreshSolana(wallet, [solanaNFT("MintA", name: "refreshed")]);
      final sending = saved.removeSolana(wallet, "MintA");

      await Future.wait([refreshing, sending]);

      expect(await saved.solanaNFTs(wallet), isEmpty);
    });

    test("many overlapping writes all land", () async {
      await Future.wait([
        for (var i = 0; i < 20; i++) saved.addSolana(wallet, solanaNFT("Mint$i")),
      ]);

      expect((await saved.solanaNFTs(wallet)).length, 20);
    });
  });

  group("SavedNFTs, evm", () {
    NFTAssetModel evmNFT(String address, String tokenId, {String? name}) => NFTAssetModel(
          tokenAddress: address,
          tokenId: tokenId,
          name: name ?? address,
          symbol: "SYM",
          normalizedMetadata: NormalizedMetadata(
            name: name,
            description: "a description",
            image: "ipfs://QmAbC",
          ),
        );

    test("an imported evm nft survives a restart", () async {
      await saved.addEvm(wallet, otherChain, evmNFT("0xabc", "7", name: "Punk"));

      final stored = await saved.evmNFTs(wallet, otherChain);

      expect(stored.length, 1);
      expect(stored.first.tokenAddress, "0xabc");
      expect(stored.first.tokenId, "7");
      expect(stored.first.name, "Punk");
      expect(stored.first.normalizedMetadata?.description, "a description");
    });

    test("stores the ipfs image through the shared gateway", () async {
      await saved.addEvm(wallet, otherChain, evmNFT("0xabc", "7"));

      final stored = await saved.evmNFTs(wallet, otherChain);

      expect(stored.first.normalizedMetadata?.imageUrl, "https://ipfs.io/ipfs/QmAbC");
    });

    test("tells two token ids of one contract apart", () async {
      await saved.addEvm(wallet, otherChain, evmNFT("0xabc", "7"));
      await saved.addEvm(wallet, otherChain, evmNFT("0xabc", "8"));

      expect((await saved.evmNFTs(wallet, otherChain)).length, 2);
    });

    test("keeps evm and solana entries apart by chain", () async {
      await saved.addEvm(wallet, otherChain, evmNFT("0xabc", "7"));
      await saved.addSolana(wallet, solanaNFT("MintA"));

      expect((await saved.evmNFTs(wallet, otherChain)).length, 1);
      expect((await saved.solanaNFTs(wallet)).length, 1);
    });
  });
}
