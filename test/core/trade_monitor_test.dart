import "package:cake_wallet/core/trade_monitor.dart";
import "package:cake_wallet/entities/exchange_api_mode.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/trades_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/dashboard/trade_list_item.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

import "../exchange/provider/fakes.dart";

/// The monitor only reads the two exchange status settings.
class _Settings extends Fake implements SettingsStore {
  @override
  bool disableAutomaticExchangeStatusUpdates = false;

  @override
  ExchangeApiMode exchangeStatus = ExchangeApiMode.enabled;
}

class _App extends Fake implements AppStore {
  @override
  final _Settings settingsStore = _Settings();
}

class _Trades extends Fake implements TradesStore {
  @override
  List<TradeListItem> trades = [];
}

Trade _trade({String? txId, TradeState state = TradeState.created}) => Trade(
  id: "request-id",
  provider: ExchangeProviderDescription.jupiter,
  state: state,
  depositAmount: Money.parse("2", CryptoCurrency.sol),
  payoutAmount: Money.parse("400", CryptoCurrency.usdcsol),
  fundingAddress: "",
  payoutAddress: "payout-address",
  refundAddress: "refund-address",
  walletId: "wallet",
  createdAt: DateTime.now(),
  txId: txId,
);

void main() {
  sqfliteFfiInit();

  late FakeSolana fakeSolana;
  late Solana? realSolana;
  late _App app;
  late _Trades trades;
  late SharedPreferences preferences;
  late TradeMonitor monitor;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await createTradeTable(db!);

    realSolana = solana;
    fakeSolana = FakeSolana()..transactionResult = true;
    solana = fakeSolana;

    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();

    app = _App();
    trades = _Trades();
    monitor = TradeMonitor(tradesStore: trades, appStore: app, preferences: preferences);
  });

  tearDown(() async {
    monitor.stopTradeMonitoring();
    solana = realSolana;
    await db?.close();
    db = null;
  });

  void listTrade(Trade trade) => trades.trades = [
    TradeListItem(trade: trade, appStore: app, key: ValueKey(trade.id)),
  ];

  test("checks a trade saved after its swap was sent right away", () async {
    await _trade(txId: "signature").save();
    listTrade(_trade(txId: "signature"));

    final checked = Trade.onChanged.stream.first;
    monitor.monitorActiveTrades("wallet");
    await checked;

    expect((await Trade.getByTradeId("request-id"))!.state, TradeState.completed);
    expect(fakeSolana.lookedUp, ["signature"]);
  });

  test("checks the stored trade, not the copy the trade list holds", () async {
    // the list still holds the trade from before the swap flow saved its txId
    await _trade(txId: "signature").save();
    listTrade(_trade());

    final checked = Trade.onChanged.stream.first;
    monitor.monitorActiveTrades("wallet");
    await checked;

    final stored = (await Trade.getByTradeId("request-id"))!;
    expect(stored.txId, "signature");
    expect(stored.state, TradeState.completed);
  });

  group("recordDeposit", () {
    test("saves the deposit and settles the trade through updateTrade", () async {
      await _trade().save();

      await monitor.recordDeposit("request-id", "signature");

      final trade = (await Trade.getByTradeId("request-id"))!;
      expect(trade.txId, "signature");
      expect(trade.state, TradeState.completed);
      expect(trade.walletId, "wallet", reason: "the stored trade is updated, not replaced");
      expect(fakeSolana.lookedUp, ["signature"]);
    });

    test("doesn't wait out the check that ran when the trade was created", () async {
      await _trade().save();
      await preferences.setString(
        "trade_request-id_updated_at",
        DateTime.now().toIso8601String(),
      );

      await monitor.recordDeposit("request-id", "signature");

      expect((await Trade.getByTradeId("request-id"))!.state, TradeState.completed);
    });

    test("settles an order the monitor expired while it was being executed", () async {
      await _trade(state: TradeState.expired).save();

      await monitor.recordDeposit("request-id", "signature");

      expect((await Trade.getByTradeId("request-id"))!.state, TradeState.completed);
    });

    test("only saves the deposit when status updates are off", () async {
      app.settingsStore.disableAutomaticExchangeStatusUpdates = true;
      await _trade().save();

      await monitor.recordDeposit("request-id", "signature");

      final trade = (await Trade.getByTradeId("request-id"))!;
      expect(trade.txId, "signature");
      expect(trade.state, TradeState.created);
      expect(fakeSolana.lookedUp, isEmpty);
    });

    test("only saves the deposit in tor only mode", () async {
      app.settingsStore.exchangeStatus = ExchangeApiMode.torOnly;
      await _trade().save();

      await monitor.recordDeposit("request-id", "signature");

      final trade = (await Trade.getByTradeId("request-id"))!;
      expect(trade.txId, "signature");
      expect(trade.state, TradeState.created);
      expect(fakeSolana.lookedUp, isEmpty);
    });

    test("ignores a trade it doesn't know", () async {
      await monitor.recordDeposit("request-id", "signature");

      expect(await Trade.getAll(), isEmpty);
      expect(fakeSolana.lookedUp, isEmpty);
    });
  });
}
