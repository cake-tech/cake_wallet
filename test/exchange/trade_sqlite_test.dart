import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/db/trade_migration.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

// the Trade table and its unique index as they were before the v16 migration
const _oldTradeSchema = """
CREATE TABLE IF NOT EXISTS Trade (
  tradeId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  id TEXT NOT NULL,
  providerRaw INTEGER NOT NULL DEFAULT 0,
  fromTitle TEXT,
  fromName TEXT,
  fromTag TEXT,
  fromFullName TEXT,
  fromDecimals INTEGER,
  fromRaw INTEGER,
  fromIconPath TEXT,
  fromFlatIconPath TEXT,
  fromChainIconPath TEXT,
  toTitle TEXT,
  toName TEXT,
  toTag TEXT,
  toFullName TEXT,
  toDecimals INTEGER,
  toRaw INTEGER,
  toIconPath TEXT,
  toFlatIconPath TEXT,
  toChainIconPath TEXT,
  stateRaw TEXT NOT NULL DEFAULT '',
  createdAt INTEGER,
  expiredAt INTEGER,
  amount TEXT NOT NULL DEFAULT '',
  receiveAmount TEXT,
  inputAddress TEXT,
  extraId TEXT,
  outputTransaction TEXT,
  refundAddress TEXT,
  walletId TEXT,
  payoutAddress TEXT,
  toAddressExtraId TEXT,
  password TEXT,
  providerId TEXT,
  providerName TEXT,
  fromWalletAddress TEXT,
  memo TEXT,
  txId TEXT,
  isRefund INTEGER DEFAULT 0,
  isSendAll INTEGER DEFAULT 0,
  router TEXT,
  needToRegisterInSwapXyz INTEGER DEFAULT 0,
  sourceTokenAddress TEXT,
  sourceTokenDecimals INTEGER,
  routerData TEXT,
  routerValue TEXT,
  routerChainId INTEGER,
  sourceTokenAmountRaw TEXT,
  requiresTokenApproval INTEGER DEFAULT 0,
  chainId INTEGER,
  fee REAL
);
""";

Trade _trade(String id, {TradeState state = TradeState.created, String? walletId}) => Trade(
  id: id,
  provider: ExchangeProviderDescription.nearIntents,
  state: state,
  depositAmount: Money.parse("0.5", CryptoCurrency.usdcEPoly),
  payoutAmount: Money.parse("0.0002", CryptoCurrency.btc),
  fundingAddress: "funding-$id",
  payoutAddress: "payout-$id",
  refundAddress: "refund-$id",
  walletId: walletId,
  providerName: "Swapter",
  createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
);

Future<Database> _openMemoryDb() =>
    databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );

void main() {
  sqfliteFfiInit();

  tearDown(() async {
    await db?.close();
    db = null;
  });

  group("Trade table", () {
    setUp(() async {
      db = await _openMemoryDb();
      await createTradeTable(db!);
    });

    test("uses the textual id as the only key", () async {
      final columns = await db!.rawQuery("PRAGMA table_info(Trade)");
      final pk = columns.where((c) => (c["pk"] as int) > 0).map((c) => c["name"]).toList();

      expect(pk, ["id"]);
      expect(columns.map((c) => c["name"]), isNot(contains("tradeId")));
      expect(
        await db!.rawQuery("SELECT name FROM sqlite_master WHERE name = 'idx_trade_id_unique'"),
        isEmpty,
      );
    });

    test("save inserts, and saving the same id again updates in place", () async {
      await _trade("abc", walletId: "wallet").save();
      await _trade("abc", state: TradeState.completed, walletId: "wallet").save();

      final all = await Trade.getAll();
      expect(all, hasLength(1));
      expect(all.single.state, TradeState.completed);
      expect(all.single.walletId, "wallet");
      expect(all.single.depositAmount.currency, CryptoCurrency.usdcEPoly);
    });

    test("an update through copyWith keeps the untouched fields", () async {
      await _trade("abc", walletId: "wallet").save();
      final stored = (await Trade.getByTradeId("abc"))!;

      await stored.copyWith(state: TradeState.refunded, txId: "tx").save();

      final updated = (await Trade.getByTradeId("abc"))!;
      expect(updated.state, TradeState.refunded);
      expect(updated.txId, "tx");
      expect(updated.walletId, "wallet");
      expect(updated.fundingAddress, "funding-abc");
      expect(updated.providerName, "Swapter");
    });

    test("different ids are separate rows", () async {
      await _trade("a").save();
      await _trade("b").save();

      expect((await Trade.getAll()).map((t) => t.id), unorderedEquals(["a", "b"]));
    });

    test("deleteTrade removes only that trade", () async {
      await _trade("a").save();
      await _trade("b").save();

      await Trade.deleteTrade(_trade("a"));

      expect((await Trade.getAll()).map((t) => t.id), ["b"]);
      expect(await Trade.getByTradeId("a"), isNull);
    });
  });

  group("migration from the old schema", () {
    setUp(() async {
      db = await _openMemoryDb();
      await db!.execute(_oldTradeSchema);
      await db!.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_trade_id_unique ON Trade (id);");
      await db!.insert("Trade", {
        "id": "legacy",
        "providerRaw": ExchangeProviderDescription.changeNow.raw,
        "fromTitle": "BTC",
        "toTitle": "XMR",
        "stateRaw": TradeState.created.raw,
        "amount": "0.1",
        "receiveAmount": "10",
        "inputAddress": "funding-legacy",
        "walletId": "wallet",
        "providerName": "Swapter",
        "createdAt": 1700000000000,
      });

      await migrateTradeTableToNewSchema(db!);
    });

    test("drops the old unique index", () async {
      expect(
        await db!.rawQuery("SELECT name FROM sqlite_master WHERE name = 'idx_trade_id_unique'"),
        isEmpty,
      );
    });

    test("moves the rows over with id as the primary key", () async {
      final migrated = (await Trade.getByTradeId("legacy"))!;

      expect(migrated.depositAmount, Money.parse("0.1", CryptoCurrency.btc));
      expect(migrated.payoutAmount, Money.parse("10", CryptoCurrency.xmr));
      expect(migrated.walletId, "wallet");
      expect(migrated.providerName, "Swapter");

      final columns = await db!.rawQuery("PRAGMA table_info(Trade)");
      expect(columns.where((c) => (c["pk"] as int) > 0).map((c) => c["name"]), ["id"]);
    });

    test("saving a migrated trade updates it instead of duplicating it", () async {
      final migrated = (await Trade.getByTradeId("legacy"))!;

      await migrated.copyWith(state: TradeState.completed).save();

      final all = await Trade.getAll();
      expect(all, hasLength(1));
      expect(all.single.state, TradeState.completed);
    });
  });
}
