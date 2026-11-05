import "dart:io";

import "package:cw_core/db/sqlite.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

// Faking the documents dir keeps getAppDir() off the platform channel, so the
// test runs with a plain `flutter test` on any host and in CI — same trick
// token_sqlite_migration_test.dart uses.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

void main() {
  final dataRoot = Directory("./test/data/scan_coverage_migration");

  setUp(() {
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
    dataRoot.createSync(recursive: true);

    PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);
    Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await db?.close();
    db = null;
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });

  test("backfillTargetHeight round-trips through save()/fromJson, including clearing it", () async {
    await initDb();
    final walletId = await db!.insert("WalletInfo", {
      "id": "backfill_target_roundtrip",
      "name": "w",
      "type": WalletType.bitcoin.index,
      "isRecovery": 0,
      "restoreHeight": 500,
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

    var wallet = (await WalletInfo.selectList("walletInfoId = ?", [walletId])).single;
    expect(wallet.backfillTargetHeight, isNull, reason: "starts unset, like any other new row");

    wallet.backfillTargetHeight = 900000;
    await wallet.save();

    wallet = (await WalletInfo.selectList("walletInfoId = ?", [walletId])).single;
    expect(wallet.backfillTargetHeight, 900000, reason: "a set target must survive a reload");

    // What _flushCheckpoint does on backfill completion (ADR-0004): clear
    // the target and persist restoreHeight in the same save() call.
    wallet.backfillTargetHeight = null;
    wallet.restoreHeight = 900000;
    await wallet.save();

    wallet = (await WalletInfo.selectList("walletInfoId = ?", [walletId])).single;
    expect(wallet.backfillTargetHeight, isNull, reason: "clearing on completion must also persist");
    expect(wallet.restoreHeight, 900000);
  });

  group("mergeCoverageRanges / isRangeFullyCovered / lowestUncoveredHeight (pure, no DB)", () {
    test("merges overlapping and adjacent ranges, leaves disjoint ones separate", () {
      final merged = mergeCoverageRanges([
        const CoverageRange(100, 200),
        const CoverageRange(201, 250), // adjacent to the first
        const CoverageRange(180, 220), // overlaps the first
        const CoverageRange(500, 600), // disjoint
      ]);

      expect(merged, [const CoverageRange(100, 250), const CoverageRange(500, 600)]);
    });

    test("isRangeFullyCovered is true only when a single merged range spans it", () {
      final ranges = [const CoverageRange(100, 200), const CoverageRange(201, 300)];
      expect(isRangeFullyCovered(ranges, 100, 300), true);
      expect(isRangeFullyCovered(ranges, 100, 301), false);
      expect(isRangeFullyCovered(ranges, 150, 250), true);
    });

    test("lowestUncoveredHeight finds the first gap", () {
      final ranges = [const CoverageRange(100, 199), const CoverageRange(250, 300)];
      expect(lowestUncoveredHeight(ranges, 100, 300), 200);
      expect(lowestUncoveredHeight(ranges, 100, 199), null);
      expect(lowestUncoveredHeight(ranges, 260, 300), null);
      expect(lowestUncoveredHeight(ranges, 0, 300), 0);
    });

    test("uncoveredRanges returns every gap, not just the first", () {
      final ranges = [const CoverageRange(100, 199), const CoverageRange(250, 300)];
      expect(uncoveredRanges(ranges, 100, 300), [const CoverageRange(200, 249)]);
      expect(
        uncoveredRanges(ranges, 0, 300),
        [const CoverageRange(0, 99), const CoverageRange(200, 249)],
      );
      expect(uncoveredRanges(ranges, 100, 199), isEmpty);
      expect(uncoveredRanges([], 0, 100), [const CoverageRange(0, 100)]);
      expect(
        uncoveredRanges(ranges, 400, 300),
        isEmpty,
        reason: "an inverted range is empty, not an error",
      );
    });

    test("highestContiguouslyCoveredFrom finds the resumable prefix", () {
      final ranges = [
        const CoverageRange(100, 199),
        const CoverageRange(200, 250),
        const CoverageRange(300, 400),
      ];
      expect(
        highestContiguouslyCoveredFrom(ranges, 100),
        250,
        reason:
            "100-199 and 200-250 are adjacent and merge; 300-400 is a separate gap-bounded island",
      );
      expect(highestContiguouslyCoveredFrom(ranges, 300), 400);
      expect(
        highestContiguouslyCoveredFrom(ranges, 260),
        259,
        reason: "floor itself isn't covered, so nothing usable — returns floor - 1",
      );
      expect(highestContiguouslyCoveredFrom([], 50), 49);
    });

    test("partitionForWorkers truncates to the lowest gaps when there are more gaps than workers",
        () {
      final gaps = [
        const CoverageRange(0, 9),
        const CoverageRange(20, 29),
        const CoverageRange(40, 49),
      ];
      expect(
        partitionForWorkers(gaps, 2),
        [const CoverageRange(0, 9), const CoverageRange(20, 29)],
        reason: "the third gap is left for a later round, not merged or dropped forever",
      );
      expect(partitionForWorkers(gaps, 3), gaps, reason: "an exact match is a plain pass-through");
    });

    test("partitionForWorkers subdivides the largest gap when there are fewer gaps than workers",
        () {
      expect(
        partitionForWorkers([const CoverageRange(0, 99)], 4),
        [
          const CoverageRange(0, 24),
          const CoverageRange(25, 49),
          const CoverageRange(50, 74),
          const CoverageRange(75, 99),
        ],
        reason: "one 100-height gap evenly quartered across 4 workers",
      );

      expect(
        partitionForWorkers([const CoverageRange(0, 49), const CoverageRange(100, 109)], 3),
        [const CoverageRange(0, 24), const CoverageRange(25, 49), const CoverageRange(100, 109)],
        reason: "only the larger gap is split; the small one is left as one chunk",
      );
    });

    test("partitionForWorkers edge cases", () {
      expect(partitionForWorkers([], 4), isEmpty);
      expect(partitionForWorkers([const CoverageRange(0, 99)], 0), isEmpty);
      expect(
        partitionForWorkers([const CoverageRange(0, 0)], 5),
        [const CoverageRange(0, 0)],
        reason: "a single-height gap can't be split further, even if workers are idle",
      );
    });

    test("markCovered never merges across historical modes", () async {
      // This exercises the DB path deliberately, not just the pure
      // functions — ADR-0013's whole point is that a historically-covered
      // and non-historically-covered range at the same heights must NOT
      // collapse into one row.
      await initDb();
      final walletId = await db!.insert("WalletInfo", {
        "id": "mode_separation_check",
        "name": "w",
        "type": WalletType.bitcoin.index,
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

      await WalletInfoScanCoverage.markCovered(
        walletInfoId: walletId,
        historical: false,
        startHeight: 100,
        endHeight: 200,
      );
      await WalletInfoScanCoverage.markCovered(
        walletInfoId: walletId,
        historical: true,
        startHeight: 100,
        endHeight: 200,
      );

      final all = await WalletInfoScanCoverage.selectList(walletId);
      expect(all.length, 2, reason: "same range, two modes, must stay two separate rows");

      final historicalOnly = await WalletInfoScanCoverage.selectList(walletId, historical: true);
      expect(historicalOnly.length, 1);
      expect(historicalOnly.first.startHeight, 100);
      expect(historicalOnly.first.endHeight, 200);
    });
  });
}
