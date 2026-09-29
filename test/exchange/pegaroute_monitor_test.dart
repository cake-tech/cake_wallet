import 'dart:async';
import 'package:cake_wallet/core/trade_monitor.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cw_core/db/sqlite.dart' as sqlite;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'pegaroute_creation_test.dart' show CapturedTrades;
import 'pegaroute_flow_test.dart';

class ManualPeriodicTimer implements Timer {
  ManualPeriodicTimer(this.callback);
  final void Function(Timer) callback;
  @override
  bool isActive = true;
  @override
  int tick = 0;
  void fire() { if (isActive) { tick++; callback(this); } }
  @override
  void cancel() { isActive = false; }
}

class MonitoredFlow extends DepositFixture {
  MonitoredFlow(super.database);
  int reads = 0;
  @override
  Future<Map<String, dynamic>> request(String method, Uri uri, Map<String, String> headers, String? body) {
    if (method == 'GET' && uri.path == '/swap/order') reads++;
    return super.request(method, uri, headers, body);
  }
}

Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerFallbackValue(WalletType.ethereum);
  registerFallbackValue(Object());
  S.current = const S();
  late Database db;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await openDepositDb();
    evm = TestEvm();
  });
  tearDown(() async { await db.close(); sqlite.db = null; });

  for (final end in ['completed', 'refunded', 'disabled']) {
    test('actual monitor follows funded orders past age limit and stops on $end', () async {
      final flow = MonitoredFlow(db);
      final created = await flow.create();
      final send = SendFixture(flow, created);
      expect(await send.prepare(), isNotNull);
      await send.commit();
      final saved = await flow.store.read('order');
      final stores = CapturedTrades();
      when(() => stores.trades).thenReturn([
        TradeListItem(trade: saved, appStore: send.app, key: const ValueKey('order'))]);
      var disabled = false;
      when(() => send.settings.disableAutomaticExchangeStatusUpdates).thenAnswer((_) => disabled);
      when(() => send.settings.exchangeStatus).thenReturn(ExchangeApiMode.enabled);
      var now = DateTime.now().add(const Duration(days: 2));
      final prefs = await SharedPreferences.getInstance();
      final monitor = TradeMonitor(tradesStore: stores, appStore: send.app, preferences: prefs,
          clock: () => now, providerFactory: (_) => flow.provider);
      addTearDown(monitor.stopTradeMonitoring);
      final timers = <ManualPeriodicTimer>[];
      runZoned(() => monitor.monitorActiveTrades('wallet'), zoneSpecification: ZoneSpecification(
          createPeriodicTimer: (self, parent, zone, duration, callback) {
            expect(duration, const Duration(minutes: 5));
            final timer = ManualPeriodicTimer(callback); timers.add(timer); return timer;
          }));
      await until(() => prefs.getString('trade_order_updated_at') != null);
      expect(flow.reads, 1);
      expect(timers.single.isActive, isTrue);
      now = now.add(const Duration(minutes: 6));
      if (end == 'disabled') {
        disabled = true;
      } else {
        flow.status = end;
        if (end == 'completed') flow.outputHash = 'd' * 64;
      }
      timers.single.fire();
      await until(() => !timers.single.isActive);
      expect(flow.reads, end == 'disabled' ? 1 : 2);
      expect((await flow.store.read('order')).txId, saved.txId);
      timers.single.fire();
      expect(flow.reads, end == 'disabled' ? 1 : 2);
    });
  }
}
