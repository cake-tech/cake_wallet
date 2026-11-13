import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/provider_registry.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/trade_creator.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _Wallet extends Fake implements WalletBase {
  _Wallet({this.type = WalletType.ethereum, int currentAccountIndex = 0})
    : walletInfo = WalletInfo.external(
        id: "wallet",
        name: "wallet",
        type: type,
        isRecovery: false,
        restoreHeight: 0,
        date: DateTime(2026),
        dirPath: "",
        path: "",
        address: "",
        currentAccountIndex: currentAccountIndex,
      );

  @override
  String get id => "wallet";

  @override
  final WalletType type;

  @override
  final WalletInfo walletInfo;
}

class _App extends Fake implements AppStore {
  _App([WalletBase? wallet]) : wallet = wallet ?? _Wallet();

  @override
  WalletBase? wallet;
}

class _Provider extends Fake implements ExchangeProvider {
  _Provider(this.description, {this.fails = false});

  @override
  final ExchangeProviderDescription description;

  final bool fails;

  late final created = _trade("${description.title}-quote", description);

  @override
  Future<Trade> createTrade({required TradeRequest request}) async =>
      fails ? throw Exception("${description.title} is down") : created;
}

class _Registry extends Fake implements ExchangeProviderRegistry {
  _Registry(Iterable<_Provider> providers)
    : _providers = {for (final provider in providers) provider.description: provider};

  final Map<ExchangeProviderDescription, _Provider> _providers;

  @override
  ExchangeProvider getProvider(ExchangeProviderDescription description) =>
      _providers[description]!;
}

Trade _trade(String id, ExchangeProviderDescription provider) => Trade(
  id: id,
  provider: provider,
  state: TradeState.created,
  depositAmount: Money.parse("0.5", CryptoCurrency.usdcEPoly),
  payoutAmount: Money.parse("0.0002", CryptoCurrency.btc),
  fundingAddress: "funding-$id",
  payoutAddress: "payout-address",
  refundAddress: "refund-address",
  createdAt: DateTime.now(),
);

ProviderRate _rate(ExchangeProviderDescription provider) => ProviderRate(
  provider: provider,
  rate: ExchangeRate.fromAmounts(
    Money.parse("0.5", CryptoCurrency.usdcEPoly),
    Money.parse("0.0002", CryptoCurrency.btc),
  ),
  limits: ExchangeLimits(),
);

final _request = TradeRequest(
  refundAddress: "refund-address",
  payoutAddress: "payout-address",
  depositAmount: Money.parse("0.5", CryptoCurrency.usdcEPoly),
  payoutAmount: Money.parse("0.0002", CryptoCurrency.btc),
  isFixedRate: false,
  toAddressExtraId: "",
);

void main() {
  sqfliteFfiInit();

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await createTradeTable(db!);
  });

  tearDown(() async {
    await db?.close();
    db = null;
  });

  group("createTrade", () {
    test("hands back the provider's own trade, so its createTransaction gets its subclass", () async {
      final provider = _Provider(ExchangeProviderDescription.swapsXyz);
      final creator = TradeCreator(appStore: _App(), registry: _Registry([provider]));

      final trade = await creator.createTrade([_rate(provider.description)], _request);

      expect(trade, same(provider.created));
    });

    test("falls through to the next provider", () async {
      final down = _Provider(ExchangeProviderDescription.changeNow, fails: true);
      final up = _Provider(ExchangeProviderDescription.swapsXyz);
      final creator = TradeCreator(appStore: _App(), registry: _Registry([down, up]));

      final trade = await creator.createTrade(
        [_rate(down.description), _rate(up.description)],
        _request,
      );

      expect(trade, same(up.created));
    });

    test("returns null when every provider fails", () async {
      final down = _Provider(ExchangeProviderDescription.changeNow, fails: true);
      final creator = TradeCreator(appStore: _App(), registry: _Registry([down]));

      expect(await creator.createTrade([_rate(down.description)], _request), isNull);
    });

    test("doesn't store anything, the swap flow decides when", () async {
      final provider = _Provider(ExchangeProviderDescription.swapsXyz);
      final creator = TradeCreator(appStore: _App(), registry: _Registry([provider]));

      await creator.createTrade([_rate(provider.description)], _request);

      expect(await Trade.getAll(), isEmpty);
    });
  });

  test("persistTrade stores the trade under the current wallet", () async {
    final creator = TradeCreator(appStore: _App(), registry: _Registry([]));

    await creator.persistTrade(_trade("order-id", ExchangeProviderDescription.swapsXyz));

    final stored = (await Trade.getAll()).single;
    expect(stored.id, "order-id");
    expect(stored.walletId, "wallet");
    expect(stored.accountIndex, 0);
  });

  test("persistTrade stores the trade under the current bitcoin account", () async {
    final app = _App(_Wallet(type: WalletType.bitcoin, currentAccountIndex: 2));
    final creator = TradeCreator(appStore: app, registry: _Registry([]));

    await creator.persistTrade(_trade("order-id", ExchangeProviderDescription.swapsXyz));

    expect((await Trade.getAll()).single.accountIndex, 2);
  });

  test("persistTrade keeps lightning-funded trades on the primary account", () async {
    final app = _App(_Wallet(type: WalletType.bitcoin, currentAccountIndex: 2));
    final creator = TradeCreator(appStore: app, registry: _Registry([]));
    final lightning = _trade("order-id", ExchangeProviderDescription.swapsXyz)
        .copyWith(depositAmount: Money.parse("0.0001", CryptoCurrency.btcln));

    await creator.persistTrade(lightning);

    expect((await Trade.getAll()).single.accountIndex, 0);
  });
}
