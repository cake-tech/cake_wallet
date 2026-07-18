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

import "package:cw_core/utils/proxy_wrapper.dart";
import 'package:flutter_test/flutter_test.dart';

import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/letsexchange_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/tor/disabled.dart';

// ─────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────

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
      //ChangeNowExchangeProvider.withAppVersion(appVersion: '621'),
      LetsExchangeExchangeProvider(),
      //TrocadorExchangeProvider(),
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
          final r = await checkProvider(provider, pair.$1, pair.$2, amount);
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
    required this.amount,
    required this.success,
    this.tradeId,
    this.confirmedAmount,
    this.confirmedReceiveAmount,
    this.errorMessage,
    this.durationMs,
  });

  final String provider;
  final CryptoCurrency from;
  final CryptoCurrency to;
  final double amount;
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
    "from": displayName(from),
    "to": displayName(to),
    "requested_amount": amount,
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
  const xmrAddress = "44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A";
  const nanoAddress = "nano_3t6k35gi95xu6tergt6p69ck76ogmitsa8mnijtpxm9fkcm736xtoncuohr3";
  const bchAddress = "bitcoincash:qp3wjpa3tjlj042z2wv7hahsldgwhwy0rq9sywjpyy";
  const dogeAddress = "DH5yaieqoZN36fDVciNyRueRGvGLR3mr7L";
  const adaAddress = "addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp";
  const zecAddress = "zs1z7rejlpsa98s2rrrfkwmaxu53e4ue0ulcrw0h4x5g8jl04tak0d3mm47vdtahatqrlkngh9slya";
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
  final header = '${r.success ? "✅" : "❌"} ${r.provider} ${displayName(r.from)} ➡️ ${displayName(r.to)} requested = ${r.amount}';
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
    CryptoCurrency from,
    CryptoCurrency to,
    double amount,
    ) async {
  final sw = Stopwatch()..start();
  try {
    // Mirrors the real app flow: a rate is always fetched before the user
    // can confirm a trade. This is also a hard requirement for some
    // providers internally (e.g. Trocador populates its enabled-provider
    // list only inside fetchRate).
    final rate = await provider.fetchRate(
      from: from,
      to: to,
      amount: amount,
      isFixedRateMode: false,
      isReceiveAmount: false,
    );

    if (rate <= 0) {
      return TradeResult(
        provider: provider.title, from: from, to: to, amount: amount, success: false,
        errorMessage: "fetchRate returned $rate — no usable quote for this pair",
        durationMs: sw.elapsedMilliseconds,
      );
    }

    final request = TradeRequest(
      fromCurrency: from,
      toCurrency: to,
      refundAddress: placeholderAddress(from),
      toAddress: placeholderAddress(to),
      fromAmount: cleanAmount(amount),
    );

    final trade = await provider.createTrade(
      request: request,
      isFixedRateMode: false,
      isSendAll: false,
    );

    return TradeResult(
      provider: provider.title, from: from, to: to, amount: amount, success: true,
      tradeId: trade.id,
      confirmedAmount: trade.amount,
      confirmedReceiveAmount: trade.receiveAmount,
      durationMs: sw.elapsedMilliseconds,
    );
  } catch (e) {
    return TradeResult(
      provider: provider.title, from: from, to: to, amount: amount, success: false,
      errorMessage: e.toString(), durationMs: sw.elapsedMilliseconds,
    );
  }
}