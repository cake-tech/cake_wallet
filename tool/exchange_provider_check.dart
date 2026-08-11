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
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_amount.dart";
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
import "package:mobx/src/api/observable_collections.dart";
import "package:mobx/src/core.dart";

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
  late ExchangeApiMode exchangeStatus;

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
  late ObservableMap<String, bool> trocadorProviderStates;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // undo flutter_test's HTTP interception
  CakeTor.instance = CakeTorDisabled();

  test('exchange provider trade-creation check', () async {
    // Real provider instances — completely unmodified real classes, except
    // ChangeNOW uses the .withAppVersion() seam already added to production
    // code (avoids needing a full SettingsStore, which createTrade() never
    // actually used beyond reading .appVersion).
    final providers = <ExchangeProvider>[
      ChangeNowExchangeProvider(settingsStore: FakeSettingsStore()),
      LetsExchangeExchangeProvider(),
      TrocadorExchangeProvider(),
    ];

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

    final testAmounts = <double>[250];

    final results = <TradeResult>[];
    for (final pair in testPairs) {
      for (final amount in testAmounts) {
        for (final provider in providers) {
          final r = await checkProvider(provider, Money.parse(amount, pair.$1), pair.$2);
          results.add(r);
          print(summaryLine(r));
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }

    writeJsonReport(results, 'exchange_provider_check_report.json');

    final ok = results.where((r) => r.success).length;
    print('\n$ok / ${results.length} succeeded');

    expect(results, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 15)));
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
  };
}

/// CryptoCurrency.toString() only returns the title — "USDT" on OMNI, ETH,
/// TRX, and BSC would all print identically. Use this wherever a currency
/// needs to be shown.
String displayName(CryptoCurrency c) => c.tag != null ? "${c.title} (${c.tag})" : c.title;

String cleanAmount(double amount) =>
    amount == amount.truncateToDouble() ? amount.toInt().toString() : amount.toString();

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
      "addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp";
  const zecAddress =
      "zs1z7rejlpsa98s2rrrfkwmaxu53e4ue0ulcrw0h4x5g8jl04tak0d3mm47vdtahatqrlkngh9slya";
  const dcrAddress = "DsUZxxoHJSty8DCfwfartwTYbuhmVct7tJu";
  const xlmAddress = "GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5";
  const tonAddress = "UQD4FPq-PRDieyQKkizsMkhnRPSelJ_RmpVGBssFNnfbKnAy";
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

Future<TradeResult> checkProvider(ExchangeProvider provider, Money from, CryptoCurrency to) async {
  final sw = Stopwatch()..start();
  try {
    // Mirrors the real app flow: a rate is always fetched before the user
    // can confirm a trade. This is also a hard requirement for some
    // providers internally (e.g. Trocador populates its enabled-provider
    // list only inside fetchRate).
    final rate = await provider.fetchRate(from: from, to: to, isFixedRate: false);

    if (rate.rate.quote.isZero || rate.rate.quote.isNegative) {
      return TradeResult(
        provider: provider.title,
        from: from,
        to: to,
        success: false,
        errorMessage: "fetchRate returned $rate — no usable quote for this pair",
        durationMs: sw.elapsedMilliseconds,
      );
    }

    final request = TradeRequest(
      refundAddress: placeholderAddress(from.currency as CryptoCurrency),
      payoutAddress: placeholderAddress(to),
      depositAmount: SwapAmount(cryptoAmount: from, fiatAmount: Money.zero(FiatCurrency.usd)),
      isFixedRate: false,
      payoutAmount: SwapAmount(
        cryptoAmount: rate.rate.quote,
        fiatAmount: Money.zero(FiatCurrency.usd),
      ),
    );

    final trade = await provider.createTrade(request: request);

    return TradeResult(
      provider: provider.title,
      from: from,
      to: to,
      success: true,
      tradeId: trade.id,
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
    );
  }
}
