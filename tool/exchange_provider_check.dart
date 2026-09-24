// tool/exchange_provider_check.manual.dart
//
// Calls the REAL, unmodified exchange provider classes — no copied logic,
// no hand-rolled HTTP. This works under `flutter test` because
// `HttpOverrides.global = null` undoes flutter_test's default behavior of
// silently intercepting every HTTP request and returning a fake empty 400
// (a documented flutter_test design choice — see TestWidgetsFlutterBinding).
//
// Only the pairs listed in [testPairs] below are run — each direction is
// independent; add both explicitly if you want both tested.
//
// NOTE: creates LIVE trades against real provider APIs. Use throw-away
// addresses only.
//
// Run with: flutter test tool/exchange_provider_check.manual.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_core/utils/proxy_logger/abstract.dart';
import 'package:http/http.dart' as http;

import "package:cake_wallet/entities/action_list_display_mode.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/cake_2fa_preset_options.dart";
import "package:cake_wallet/entities/country.dart";
import "package:cake_wallet/entities/exchange_api_mode.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/entities/pin_code_required_duration.dart";
import "package:cake_wallet/entities/seed_phrase_length.dart";
import "package:cake_wallet/entities/seed_type.dart";
import "package:cake_wallet/entities/sort_balance_types.dart";
import "package:cake_wallet/entities/sync_status_display_mode.dart";
import "package:cake_wallet/entities/wallet_list_order_types.dart";
import "package:cake_wallet/exchange/provider/changenow/changenow_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/letsexchange/letsexchange_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/trocador/trocador_exchange_provider.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/provider_registry.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/settings/sync_mode.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/node.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/wallet_type.dart";
import 'package:flutter_test/flutter_test.dart';

import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import "package:mobx/mobx.dart";
import "package:mobx/src/api/observable_collections.dart";
import "package:mobx/src/core.dart";
import "package:shared_preferences/shared_preferences.dart";

// ─────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────

class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore();

  @override
  late ObservableList<ActionListDisplayMode> actionlistDisplayMode;

  @override
  late bool allowBiometricalAuthentication;

  @override
  String get appVersion => "6.4.1";

  @override
  set appVersion(String _) => throw UnimplementedError();

  @override
  late AutoGenerateSubaddressStatus autoGenerateSubaddressStatus;

  @override
  late String backgroundImage;

  @override
  late BalanceDisplayMode balanceDisplayMode;

  @override
  late int balanceHideCounter;

  @override
  late BitcoinSeedType bitcoinSeedType;

  @override
  late bool contactListAscending;

  @override
  late FilterListOrderType contactListOrder;

  @override
  late bool currentBuiltinTor;

  @override
  late bool currentSyncAll;

  @override
  late SyncMode currentSyncMode;

  @override
  late int customBitcoinFeeRate;

  @override
  late bool decentralizedExchangesPromptDismissed;

  @override
  late String defaultBananoRep;

  @override
  late String defaultNanoRep;

  @override
  late String deviceName;

  @override
  late bool disableAutomaticExchangeStatusUpdates;

  @override
  late bool disableBulletin;

  @override
  late bool disableTradeOption;

  @override
  late BitcoinAmountDisplayMode displayAmountsInSatoshi;

  @override
  late bool enableAutomaticNodeSwitching;

  @override
  late bool enableDuressPin;

  @override
  late ObservableSet<int> evmHiddenChainIds;

  @override
  late ExchangeApiMode exchangeStatus = ExchangeApiMode.enabled;

  @override
  late FiatApiMode fiatApiMode;

  @override
  late FiatCurrency fiatCurrency;

  @override
  late bool forceDecentralizedExchanges;

  @override
  late bool hasEnabledMwebBefore;

  @override
  late bool isAppSecure;

  @override
  late bool isBitcoinBuyEnabled;

  @override
  late String languageCode;

  @override
  late bool lookupsBip353;

  @override
  late bool lookupsENS;

  @override
  late bool lookupsFio;

  @override
  late bool lookupsLNUrl;

  @override
  late bool lookupsMastodon;

  @override
  late bool lookupsNostr;

  @override
  late bool lookupsOpenAlias;

  @override
  late bool lookupsThorChain;

  @override
  late bool lookupsTwitter;

  @override
  late bool lookupsUnstoppableDomains;

  @override
  late bool lookupsWellKnown;

  @override
  late bool lookupsYatService;

  @override
  late bool lookupsZanoAlias;

  @override
  late bool lookupsZcashAddress;

  @override
  late bool lookupsZcashNames;

  @override
  late MoneroSeedType moneroSeedType;

  @override
  late bool mwebAdDismissed;

  @override
  late bool mwebAlwaysScan;

  @override
  late bool mwebCardDisplay;

  @override
  late bool mwebEnabled;

  @override
  late String mwebNodeUri;

  @override
  late NanoSeedType nanoSeedType;

  @override
  late ObservableMap<WalletType, Node> nodes;

  @override
  late int numberOfFailedTokenTrials;

  @override
  late int pinCodeLength;

  @override
  late bool pinNativeTokenAtTop;

  @override
  late PinCodeRequiredDuration pinTimeOutDuration;

  @override
  late ObservableMap<WalletType, Node> powNodes;

  @override
  late ObservableMap<WalletType, TransactionPriority> priority;

  @override
  late SeedPhraseLength seedPhraseLength;

  @override
  late Cake2FAPresetsOptions selectedCake2FAPreset;

  @override
  late Country? selectedCakePayCountry;

  @override
  late bool shouldRequireTOTP2FAForAccessingWallet;

  @override
  late bool shouldRequireTOTP2FAForAddingContacts;

  @override
  late bool shouldRequireTOTP2FAForAllSecurityAndBackupSettings;

  @override
  late bool shouldRequireTOTP2FAForCreatingNewWallets;

  @override
  late bool shouldRequireTOTP2FAForExchangesToExternalWallets;

  @override
  late bool shouldRequireTOTP2FAForExchangesToInternalWallets;

  @override
  late bool shouldRequireTOTP2FAForSendsToContact;

  @override
  late bool shouldRequireTOTP2FAForSendsToInternalWallets;

  @override
  late bool shouldRequireTOTP2FAForSendsToNonContact;

  @override
  late bool shouldSaveRecipientAddress;

  @override
  late bool shouldShowDEuroDisclaimer;

  @override
  late bool shouldShowMarketPlaceInDashboard;

  @override
  late bool shouldShowRepWarning;

  @override
  late bool shouldShowYatPopup;

  @override
  late bool showAddressBookPopupEnabled;

  @override
  late bool showPayjoinCard;

  @override
  late bool showZcashMissingFundsCard;

  @override
  late bool silentPaymentsCardDisplay;

  @override
  late SortBalanceBy sortBalanceBy;

  @override
  late SyncStatusDisplayMode syncStatusDisplayMode;

  @override
  late String totpSecretKey;

  @override
  late ObservableMap<String, bool> trocadorProviderStates = {
    "Swapter": true,
    "StealthEx": true,
    "Simpleswap": true,
    "Swapuz": true,
    "ChangeNow": true,
    "Changehero": true,
    "FixedFloat": true,
    "LetsExchange": true,
    "Exolix": true,
    "Godex": true,
    "Exch": true,
    "CoinCraddle": true,
    "Alfacash": true,
    "LocalMonero": true,
    "XChange": true,
    "NeroSwap": true,
    "Changee": true,
    "BitcoinVN": true,
    "EasyBit": true,
    "WizardSwap": true,
    "Quantex": true,
    "SwapSpace": true
  }.asObservable();

  @override
  late bool useArbiScan;

  @override
  late bool useBaseScan;

  @override
  late bool useBlinkProtection;

  @override
  late bool useBscScan;

  @override
  late bool useEtherscan;

  @override
  late bool useMempoolFeeAPI;

  @override
  late bool usePayjoin;

  @override
  late bool usePolygonScan;

  @override
  late bool useTOTP2FA;

  @override
  late bool useTronGrid;

  @override
  late bool walletListAscending;

  @override
  late FilterListOrderType walletListOrder;

  @override
  late bool zcashMigrationModalViewed;

  @override
  // TODO: implement context
  ReactiveContext get context => throw UnimplementedError();

  @override
  Node getCurrentNode(WalletType walletType, {int? chainId}) {
    // TODO: implement getCurrentNode
    throw UnimplementedError();
  }

  @override
  Node getCurrentPowNode(WalletType walletType) {
    // TODO: implement getCurrentPowNode
    throw UnimplementedError();
  }

  @override
  TransactionPriority? getPriority(WalletType walletType, {int? chainId}) {
    // TODO: implement getPriority
    throw UnimplementedError();
  }

  @override
  Future<void> reload() {
    // TODO: implement reload
    throw UnimplementedError();
  }

  @override
  Future<void> saveMapToString(String key, Map<String, bool> map) {
    // TODO: implement saveMapToString
    throw UnimplementedError();
  }

  @override
  void setEvmHiddenChainIds(Set<int> chainIds) {
    // TODO: implement setEvmHiddenChainIds
  }

  @override
  void setPriority(WalletType walletType, TransactionPriority priority, {int? chainId}) {
    // TODO: implement setPriority
  }

  @override
  Future<void> setShouldShowReceiveWarning(bool value) {
    // TODO: implement setShouldShowReceiveWarning
    throw UnimplementedError();
  }

  @override
  Future<void> setTrocadorProviderState(String providerName, bool state) {
    // TODO: implement setTrocadorProviderState
    throw UnimplementedError();
  }

  @override
  // TODO: implement shouldShowReceiveWarning
  bool get shouldShowReceiveWarning => throw UnimplementedError();

  @override
  Future<void> updateAllTrocadorProviderStates(List<String> availableProviders) {
    // TODO: implement updateAllTrocadorProviderStates
    throw UnimplementedError();
  }
}

class FakeSharedPreferences implements SharedPreferences {
  @override
  Future<bool> clear() {
    // TODO: implement clear
    throw UnimplementedError();
  }

  @override
  Future<bool> commit() {
    // TODO: implement commit
    throw UnimplementedError();
  }

  @override
  bool containsKey(String key) {
    // TODO: implement containsKey
    throw UnimplementedError();
  }

  @override
  Object? get(String key) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  bool? getBool(String key) {
    // TODO: implement getBool
    throw UnimplementedError();
  }

  @override
  double? getDouble(String key) {
    // TODO: implement getDouble
    throw UnimplementedError();
  }

  @override
  int? getInt(String key) {
    // TODO: implement getInt
    throw UnimplementedError();
  }

  @override
  Set<String> getKeys() {
    // TODO: implement getKeys
    throw UnimplementedError();
  }

  @override
  String? getString(String key) {
    // TODO: implement getString
    throw UnimplementedError();
  }

  @override
  List<String>? getStringList(String key) {
    // TODO: implement getStringList
    throw UnimplementedError();
  }

  @override
  Future<void> reload() {
    // TODO: implement reload
    throw UnimplementedError();
  }

  @override
  Future<bool> remove(String key) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  Future<bool> setBool(String key, bool value) {
    // TODO: implement setBool
    throw UnimplementedError();
  }

  @override
  Future<bool> setDouble(String key, double value) {
    // TODO: implement setDouble
    throw UnimplementedError();
  }

  @override
  Future<bool> setInt(String key, int value) {
    // TODO: implement setInt
    throw UnimplementedError();
  }

  @override
  Future<bool> setString(String key, String value) {
    // TODO: implement setString
    throw UnimplementedError();
  }

  @override
  Future<bool> setStringList(String key, List<String> value) {
    // TODO: implement setStringList
    throw UnimplementedError();
  }

}

/// Records every HTTP exchange the providers make, so a failure can be
/// reported with the actual request/response that produced it instead of
/// just a hand-written exception string. Hooks the seam ProxyWrapper
/// already exposes — no provider code is touched.
class WireLog implements ProxyLogger {
  final List<Map<String, String>> entries = [];

  @override
  void log({
    required Uri? uri,
    required RequestMethod method,
    required Uint8List body,
    required http.Response? response,
    required RequestNetwork network,
    required String? error,
  }) {
    entries.add({
      "uri": uri?.toString() ?? "",
      "request": body.isEmpty ? "" : utf8.decode(body, allowMalformed: true),
      "status": response?.statusCode.toString() ?? "",
      "response": _clip(response?.body ?? ""),
      if (error != null) "error": error,
    });
  }

  void clear() => entries.clear();

  static String _clip(String s) => s.length > 1200 ? "${s.substring(0, 1200)}…[clipped]" : s;
}

final wire = WireLog();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // undo flutter_test's HTTP interception
  CakeTor.instance = CakeTorDisabled();
  ProxyWrapper.logger = wire;

  test('exchange provider trade-creation check', () async {
    // Real provider instances — completely unmodified real classes, except
    // ChangeNOW uses the .withAppVersion() seam already added to production
    // code (avoids needing a full SettingsStore, which createTrade() never
    // actually used beyond reading .appVersion).
    final registry = ExchangeProviderRegistry(sharedPreferences: FakeSharedPreferences(), settingsStore: FakeSettingsStore());
    final providers = registry.allProviders.map(registry.getProvider).toList();
    // Explicit pairs only — each direction is independent. BTC is used as
    // the hub currency here, paired both ways with every currency we have
    // a real placeholder address for above. Add more pairs as needed —
    // nothing runs unless it's listed here.
    final testPairs = <(CryptoCurrency, CryptoCurrency)>[
      (CryptoCurrency.btc, CryptoCurrency.usdterc20),
      (CryptoCurrency.maticpoly, CryptoCurrency.btc),
      (CryptoCurrency.usdterc20, CryptoCurrency.btc),
      (CryptoCurrency.usdterc20, CryptoCurrency.nano),
      (CryptoCurrency.usdterc20, CryptoCurrency.zano),
      (CryptoCurrency.usdterc20, CryptoCurrency.near),
      (CryptoCurrency.btc, CryptoCurrency.eth),
      (CryptoCurrency.eth, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.bnb),
      (CryptoCurrency.bnb, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.ltc),
      (CryptoCurrency.ltc, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.xrp),
      (CryptoCurrency.xrp, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.trx),
      (CryptoCurrency.trx, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.sol),
      (CryptoCurrency.sol, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.xmr),
      (CryptoCurrency.xmr, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.nano),
      (CryptoCurrency.nano, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.bch),
      (CryptoCurrency.bch, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.doge),
      (CryptoCurrency.doge, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.ada),
      (CryptoCurrency.ada, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.zec),
      (CryptoCurrency.zec, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.dcr),
      (CryptoCurrency.dcr, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.xlm),
      (CryptoCurrency.xlm, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.ton),
      (CryptoCurrency.ton, CryptoCurrency.btc),
      (CryptoCurrency.btc, CryptoCurrency.near),
      (CryptoCurrency.near, CryptoCurrency.btc),
    ];

    // Optional filters so a single provider / pair can be re-run quickly while
    // chasing one bug: ONLY=Trocador,ChangeNOW  PAIR=BTC-LTC
    final only = Platform.environment["ONLY"]
        ?.split(",")
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    // PAIR accepts a comma-separated list: PAIR=BTC-LTC,USDT-BTC
    final pairFilter = Platform.environment["PAIR"]
        ?.toUpperCase()
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final selectedProviders = only == null
        ? providers
        : providers.where((p) => only.contains(p.title.toLowerCase())).toList();
    final selectedPairs = pairFilter == null
        ? testPairs
        : testPairs
              .where((p) => pairFilter.contains("${p.$1.title}-${p.$2.title}".toUpperCase()))
              .toList();

    final results = <TradeResult>[];
    for (final pair in selectedPairs) {
      for (final provider in selectedProviders) {
        final r = await checkProvider(provider, baselineAmount(pair.$1), pair.$2);
        results.add(r);
        print(summaryLine(r));
        // Written every iteration so a long run can be inspected (or killed)
        // without losing what it already found.
        writeJsonReport(results, 'exchange_provider_check_report.json');
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    writeJsonReport(results, 'exchange_provider_check_report.json');

    final ok = results.where((r) => r.success).length;
    print('\n$ok / ${results.length} succeeded');

    expect(results, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 90)));
}

// ─────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────

class TradeResult {
  TradeResult({
    required this.provider,
    required this.from,
    required this.to,
    required this.success,
    this.tradeId,
    this.confirmedAmount,
    this.confirmedReceiveAmount,
    this.errorMessage,
    this.durationMs,
    this.wireLog = const [],
  });

  final String provider;
  final Money from;
  final CryptoCurrency to;
  final bool success;
  final String? tradeId;

  // What the provider actually confirmed, as opposed to what we requested —
  // these come straight off the real Trade object, only present on success.
  final String? confirmedAmount;
  final String? confirmedReceiveAmount;
  final String? errorMessage;
  final int? durationMs;

  /// The actual HTTP exchanges behind this result — the only reliable way to
  /// tell a provider-side rejection from a bug in our request.
  final List<Map<String, String>> wireLog;

  Map<String, dynamic> toJson() => {
    "provider": provider,
    "from": from.serialized,
    "to": displayName(to),
    "success": success,
    "trade_id": tradeId,
    "confirmed_amount": confirmedAmount,
    "confirmed_receive_amount": confirmedReceiveAmount,
    "duration_ms": durationMs,
    // Only include diagnostic detail when something actually went wrong.
    if (!success) "error": errorMessage,
    if (!success) "wire": wireLog,
  };
}

/// CryptoCurrency.toString() only returns the title — "USDT" on OMNI, ETH,
/// TRX, and BSC would all print identically. Use this wherever a currency
/// needs to be shown.
String displayName(CryptoCurrency c) => c.tag != null ? "${c.title} (${c.tag})" : c.title;

String cleanAmount(double amount) =>
    amount == amount.truncateToDouble() ? amount.toInt().toString() : amount.toString();

/// Roughly $250 worth of each currency. Testing a flat "250 units" of
/// everything is meaningless — 250 BTC is ~$25M (always over every
/// provider's max) while 250 DOGE is ~$50 (under most minimums), so nearly
/// every result was really just an out-of-range rejection. Prices are
/// order-of-magnitude only; [checkProvider] then corrects the amount into
/// whatever range the provider itself reports.
const _approxUsdPrice = <String, double>{
  "BTC": 100000,
  "ETH": 4000,
  "BNB": 900,
  "LTC": 120,
  "XRP": 2.5,
  "TRX": 0.3,
  "SOL": 200,
  "XMR": 250,
  "XNO": 1,
  "NANO": 1,
  "BCH": 600,
  "DOGE": 0.2,
  "ADA": 0.9,
  "ZEC": 60,
  "DCR": 20,
  "XLM": 0.4,
  "TON": 3,
  "NEAR": 4,
  "USDT": 1,
  "USDC": 1,
  "POL": 0.4,
  "MATIC": 0.4,
  "ZANO": 2,
};

Money baselineAmount(CryptoCurrency c) {
  // AMOUNT=250 forces a literal unit amount for every currency, bypassing the
  // USD estimate — useful when reproducing a specific out-of-range report.
  final override = Platform.environment["AMOUNT"];
  if (override != null) {
    return Money.parse(override, c);
  }

  const targetUsd = 250.0;
  final price = _approxUsdPrice[c.title.toUpperCase()] ?? 1.0;
  final units = targetUsd / price;

  // Keep it to a sane number of decimals — some providers reject amounts with
  // more precision than the asset actually has.
  final decimals = units >= 100 ? 0 : (units >= 1 ? 3 : 6);

  return Money.parse(units.toStringAsFixed(decimals), c);
}

/// Well-known public / test addresses only — never used to hold real funds.
String placeholderAddress(CryptoCurrency c) {
  final title = c.title.toUpperCase();
  final tag = c.tag?.toUpperCase();

  const evmAddress = "0x8297534c2c77493453f0a5EaDBa14ffAC76A5930";
  const btcAddress = "bc1quvd6c6f2t6fa7f8q7rdcwc6tt9cx2j9sfarxqc";
  const ltcAddress = "ltc1q8c6fshw2dlwun7ekn9qwf37cu2rn755u9ym7p0";
  const xrpAddress = "rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpAYe";
  const trxAddress = "TN3W4H6rK2ce4vX9YnFQHwKENnHjoxb3m9";
  const solAddress = "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM";
  const xmrAddress =
      "44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A";
  const nanoAddress = "nano_3t6k35gi95xu6tergt6p69ck76ogmitsa8mnijtpxm9fkcm736xtoncuohr3";
  const bchAddress = "bitcoincash:qp3wjpa3tjlj042z2wv7hahsldgwhwy0rq9sywjpyy";
  const dogeAddress = "DH5yaieqoZN36fDVciNyRueRGvGLR3mr7L";
  const adaAddress =
      "addr1qyu79rkw3ka62yepygnjw4gdu3kmr5h594kr4tnecplk40pln7kc8vu04g8y0d0nflz54qvclf3umm65hd6scg6wlrys77armh";
  // Transparent (t1), not shielded — most exchanges reject zs1… payouts.
  const zecAddress = "t1Kct6a5dkPGEAU9VpwwqBFFHLusvv94cwn";
  const dcrAddress = "DsUZxxoHJSty8DCfwfartwTYbuhmVct7tJu";
  const xlmAddress = "GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5";
  const tonAddress = "UQBIulOf9HyaNPy41KGkGpvRBXZ_0yR76iEUFjc3MM3QIKyR";
  const nearAddress = "test.near";
  const zanoAddress = "z1q9w0g5x7v8y6r4t3s2u1p0n9m8l7k6j5h4g3f2e1d0c9b8a7s6d5f4g3h2j1k0";

  // Network/tag takes priority — an ERC-20/BEP-20/etc token is an EVM
  // address regardless of its title (e.g. USDT with tag ETH). Falls through
  // to matching on title for native coins that carry no tag (e.g. BTC, ETH).
  return switch (tag) {
    "ETH" || "BSC" || "POL" || "ARB" || "BASE" => evmAddress,
    "TRX" => trxAddress,
    "SOL" => solAddress,
    _ => switch (title) {
      "ETH" || "BNB" => evmAddress,
      "BTC" => btcAddress,
      "LTC" => ltcAddress,
      "XRP" => xrpAddress,
      "TRX" => trxAddress,
      "SOL" => solAddress,
      "XMR" => xmrAddress,
      "XNO" || "NANO" => nanoAddress,
      "BCH" => bchAddress,
      "DOGE" => dogeAddress,
      "ADA" => adaAddress,
      "ZEC" => zecAddress,
      "DCR" => dcrAddress,
      "XLM" => xlmAddress,
      "TON" => tonAddress,
      "NEAR" => nearAddress,
      "ZANO" => zanoAddress,
      _ => '',
    },
  };
}

void writeJsonReport(List<TradeResult> results, String path) {
  final data = {
    "generated_at": DateTime.now().toIso8601String(),
    "succeeded": results.where((r) => r.success).length,
    "failed": results.where((r) => !r.success).length,
    "results": results.map((r) => r.toJson()).toList(),
  };
  File(path).writeAsStringSync(const JsonEncoder.withIndent("  ").convert(data));
}

String summaryLine(TradeResult r) {
  final header =
      '${r.success ? "✅" : "❌"} ${r.provider} ${r.from.currency.symbol} ➡️ ${displayName(r.to)} requested = ${r.from.serialized}';
  if (r.success) {
    return '$header confirmed = ${r.confirmedAmount} ➡️ ${r.confirmedReceiveAmount} trade_id = ${r.tradeId}';
  }
  return '$header error = "${r.errorMessage}"';
}

// ─────────────────────────────────────────────────────────────────────────
// Generic runner — works against any real ExchangeProvider, unmodified
// ─────────────────────────────────────────────────────────────────────────

Future<TradeResult> checkProvider(
  ExchangeProvider provider,
  Money baseline,
  CryptoCurrency to,
) async {
  final sw = Stopwatch()..start();
  wire.clear();
  // FIXED=1 exercises the fixed-rate path, which is otherwise never covered.
  final isFixedRate = Platform.environment["FIXED"] != null;
  var from = baseline;
  try {
    // Mirrors the real app flow: a rate is always fetched before the user
    // can confirm a trade. This is also a hard requirement for some
    // providers internally (e.g. Trocador populates its enabled-provider
    // list only inside fetchRate).
    var rate = await provider.fetchRate(from: from, to: to, isFixedRate: isFixedRate);

    // Our baseline is a rough USD guess, so it can easily land outside a
    // provider's accepted range. Being out of range is expected behavior,
    // not a bug — so retry once inside the range the provider just told us
    // about, and only then judge the result.
    final corrected = Platform.environment["NOCORRECT"] == null
        ? amountWithinLimits(from, rate.limits)
        : null;
    if (corrected != null) {
      from = corrected;
      rate = await provider.fetchRate(from: from, to: to, isFixedRate: isFixedRate);
    }

    if (rate.rate.quote.isZero || rate.rate.quote.isNegative) {
      return TradeResult(
        provider: provider.title,
        from: from,
        to: to,
        success: false,
        errorMessage: "fetchRate returned $rate — no usable quote for this pair",
        durationMs: sw.elapsedMilliseconds,
        wireLog: List.of(wire.entries),
      );
    }

    final request = TradeRequest(
      refundAddress: placeholderAddress(from.currency as CryptoCurrency),
      payoutAddress: placeholderAddress(to),
      depositAmount: from,
      isFixedRate: isFixedRate,
      payoutAmount: rate.rate.convert(from),
    );

    final trade = await provider.createTrade(request: request);

    return TradeResult(
      provider: provider.title,
      from: from,
      to: to,
      success: true,
      tradeId: trade.id,
      confirmedAmount: trade.depositAmount.toStringWithSymbol(),
      confirmedReceiveAmount: trade.payoutAmount.toStringWithSymbol(),
      durationMs: sw.elapsedMilliseconds,
    );
  } catch (e) {
    return TradeResult(
      provider: provider.title,
      from: from,
      to: to,
      success: false,
      errorMessage: e.toString(),
      durationMs: sw.elapsedMilliseconds,
      wireLog: List.of(wire.entries),
    );
  }
}

/// Returns an amount comfortably inside [limits], or null when [amount]
/// already fits (or the provider reported no usable limits). Backs off the
/// edges because several providers reject an amount exactly equal to their
/// own stated min/max.
Money? amountWithinLimits(Money amount, ExchangeLimits limits) {
  final min = limits.min;
  final max = limits.max;

  if (min != null && min.currency == amount.currency && amount <= min) {
    final bumped = min + (min / BigInt.from(5)); // min * 1.2
    return (max != null && bumped >= max) ? null : bumped;
  }

  if (max != null && max.currency == amount.currency && amount >= max) {
    final reduced = max / BigInt.from(2);
    return (min != null && reduced <= min) ? null : reduced;
  }

  return null;
}
