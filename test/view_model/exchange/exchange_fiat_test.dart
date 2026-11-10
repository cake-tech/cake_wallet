import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/exchange_api_mode.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/dashboard/trades_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/contact_list/contact_list_view_model.dart";
import "package:cake_wallet/view_model/exchange/exchange_view_model.dart";
import "package:cake_wallet/view_model/send/fees_view_model.dart";
import "package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart" as sqlite;
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show Observable, ObservableMap, runInAction;
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _MockSettings extends Mock implements SettingsStore {}

class _MockApp extends Mock implements AppStore {}

class _MockTrades extends Mock implements TradesStore {}

class _MockContacts extends Mock implements ContactListViewModel {}

class _MockUnspent extends Mock implements UnspentCoinsListViewModel {}

class _MockFees extends Mock implements FeesViewModel {}

class _MockProvider extends Mock implements ExchangeProvider {}

class _MockAddresses extends Mock implements WalletAddresses {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

// Keep real amount conversion and price fetching; suppress unrelated quote/balance work.
class _ExchangeProbe extends ExchangeViewModelBase {
  _ExchangeProbe(
    AppStore app,
    SharedPreferences preferences,
    UnspentCoinsListViewModel unspent,
    FeesViewModel fees,
    FiatConversionStore prices,
    this.testProvider,
  ) : super(app, _MockTrades(), preferences, _MockContacts(), unspent, fees, prices);

  final ExchangeProvider testProvider;

  @override
  List<ExchangeProvider> get providerList => [testProvider];
  @override
  set providerList(List<ExchangeProvider> value) {}
  @override
  Future<void> loadLimits() async {}
  @override
  Future<void> calculateBestRate() async {}
  @override
  Future<void> updateDepositAvailableAmount() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database? originalDatabase;
  late FiatConversionStore prices;
  late _ExchangeProbe model;
  late Observable<FiatCurrency> fiat;
  late List<CryptoCurrency> requested;
  late List<CryptoCurrency> initialRequested;

  setUpAll(() async {
    originalDatabase = sqlite.db;
    sqfliteFfiInit();
    sqlite.db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await sqlite.db!.execute("CREATE TABLE walletInfo (id INTEGER, sortOrder INTEGER)");
  });

  tearDownAll(() async {
    await sqlite.db!.query("walletInfo");
    await sqlite.db!.close();
    sqlite.db = originalDatabase;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final settings = _MockSettings();
    final app = _MockApp();
    final wallet = _MockWallet();
    final addresses = _MockAddresses();
    final unspent = _MockUnspent();
    final fees = _MockFees();
    final provider = _MockProvider();
    fiat = Observable(FiatCurrency.usd);
    requested = [];
    when(() => settings.fiatCurrency).thenAnswer((_) => fiat.value);
    when(() => settings.fiatApiMode).thenReturn(FiatApiMode.enabled);
    when(() => settings.exchangeStatus).thenReturn(ExchangeApiMode.enabled);
    when(() => settings.forceDecentralizedExchanges).thenReturn(false);
    when(() => settings.trocadorProviderStates).thenReturn(ObservableMap<String, bool>());
    when(() => app.settingsStore).thenReturn(settings);
    when(() => app.wallet).thenReturn(wallet);
    when(() => app.amountParsingProxy)
        .thenReturn(const AmountParsingProxy(BitcoinAmountDisplayMode.bitcoin));
    when(() => wallet.currency).thenReturn(CryptoCurrency.xmr);
    when(() => wallet.type).thenReturn(WalletType.monero);
    when(() => wallet.walletAddresses).thenReturn(addresses);
    when(() => addresses.addressForExchange).thenReturn("test-address");
    when(unspent.initialSetup).thenAnswer((_) async {});
    when(() => fees.isFiatDisabled).thenReturn(false);
    when(() => provider.title).thenReturn("Test provider");
    when(() => provider.isEnabled).thenReturn(true);
    when(() => provider.description).thenReturn(ExchangeProviderDescription.changeNow);
    when(provider.checkIsAvailable).thenAnswer((_) async => true);
    prices = FiatConversionStore(
      settingsStore: settings,
      fetchPrice: ({required crypto, required fiat, required torOnly}) async {
        requested.add(crypto);
        final usd = crypto == CryptoCurrency.xmr ? 300.0 : 100000.0;
        return fiat == FiatCurrency.usd ? usd : usd * 40;
      },
    );
    model = _ExchangeProbe(app, preferences, unspent, fees, prices, provider);
    initialRequested = List.of(requested);
    model.bestRate = 2;
    await Future.wait([
      prices.fetchPrice(CryptoCurrency.xmr),
      prices.fetchPrice(CryptoCurrency.btc),
    ]);
  });

  tearDown(() async {
    model.dispose();
    prices.dispose();
    await sqlite.db!.query("walletInfo");
  });

  test("opening Swap requests prices for both initial assets", () {
    expect(initialRequested, containsAll([CryptoCurrency.xmr, CryptoCurrency.btc]));
  });

  test("changing fiat preserves crypto amounts and updates both fiat equivalents", () async {
    await model.changeDepositAmount(amount: "1", isCanonical: true);
    expect(model.depositAmountFiat, "300.00");
    expect(model.receiveAmountFiat, "200000.00");
    runInAction(() => fiat.value = FiatCurrency.uah);
    expect(model.depositAmount, "1");
    expect(model.receiveAmount, "2");
    expect(model.depositAmountFiat, isEmpty);
    expect(model.receiveAmountFiat, isEmpty);
    await Future.wait(
      [prices.fetchPrice(CryptoCurrency.xmr), prices.fetchPrice(CryptoCurrency.btc)],
    );
    expect(model.depositAmountFiat, "12000.00");
    expect(model.receiveAmountFiat, "8000000.00");
  });

  test("fiat entry divides by the current price on both sides", () async {
    runInAction(() => fiat.value = FiatCurrency.uah);
    await Future.wait(
      [prices.fetchPrice(CryptoCurrency.xmr), prices.fetchPrice(CryptoCurrency.btc)],
    );
    model.setDepositAmountFromFiat(fiatAmount: "12000");
    expect(model.depositAmount, "1");
    model.setReceiveAmountFromFiat(fiatAmount: "4000000");
    expect(model.receiveAmount, "1");
    expect(model.depositAmount, "0.5");
  });

  test("an external deposit asset refreshes and converts with the selected fiat", () async {
    model.changeDepositCurrency(currency: CryptoCurrency.eth);
    model.bestRate = 2;
    await prices.fetchPrice(CryptoCurrency.eth);
    await model.changeDepositAmount(amount: "0.25", isCanonical: true);
    expect(model.depositAmountFiat, "25000.00");
    runInAction(() => fiat.value = FiatCurrency.uah);
    await prices.fetchPrice(CryptoCurrency.eth);
    expect(model.depositAmountFiat, "1000000.00");
    model.setDepositAmountFromFiat(fiatAmount: "1000000");
    expect(model.depositAmount, "0.25");
  });

  test("fiat input cannot alter amounts while the new rate is unavailable", () async {
    await model.changeDepositAmount(amount: "1", isCanonical: true);
    runInAction(() => fiat.value = FiatCurrency.uah);
    model.setDepositAmountFromFiat(fiatAmount: "12000");
    model.setReceiveAmountFromFiat(fiatAmount: "4000000");
    expect(model.depositAmount, "1");
    expect(model.receiveAmount, "2");
  });
}
