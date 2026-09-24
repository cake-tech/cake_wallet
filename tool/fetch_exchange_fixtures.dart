// Fetches real responses from the exchange APIs and writes them to disk verbatim, so the
// *_api_schema.dart deserialization can be unit tested against what the providers actually send.
//
// Response bodies are written byte for byte. Nothing is decoded, re-encoded or pretty printed -
// a fixture is exactly what came off the wire, including whitespace and key order.
//
// Every provider in lib/exchange/provider is fetched, including the endpoints that create an
// order. Those register real records with the providers - no funds move, nothing is sent until a
// user deposits - and the payout and refund address is _payoutAddress below.
//
// Usage:
//   dart run tool/fetch_exchange_fixtures.dart
//   dart run tool/fetch_exchange_fixtures.dart --out test/exchange/fixtures
//
// The status fixtures reuse the id of the order created earlier in the same run, so nothing has to
// be passed in. If a create fails there is no id to chain, and its status fixture is skipped.
//
// A fixture whose api key is missing from .secrets.g.dart throws MissingApiKeyException. That is
// reported per provider and the run carries on, so a missing key only costs you that provider.

import "dart:convert";
import "dart:io";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:http/http.dart" as http;

const _defaultOut = "test/exchange/fixtures";

const _ethAddress = "0x00D283fFCb70F7b9A1d844e54A1AdE61E5443B6C"; // eth1
const _solAddress = "An2Y2fsUYKfYvN1zF89GAqR1e6GUMBg3qA83Y5ZWDf8L"; // sol1

const _nativeEvmToken = "0x0000000000000000000000000000000000000000";
const _usdtErc20 = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const _solMint = "So11111111111111111111111111111111111111112";
const _usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";

class MissingApiKeyException implements Exception {
  MissingApiKeyException(this.secretName);

  final String secretName;

  @override
  String toString() => "missing api key: secrets.$secretName is empty, skipping";
}

String _requireKey(String secretName, String value) {
  if (value.trim().isEmpty) {
    throw MissingApiKeyException(secretName);
  }
  return value;
}

class Fixture {
  Fixture(
    this.provider,
    this.name,
    this.request, {
    this.expectSuccess = true,
    this.createsOrder = false,
    this.needsId = false,
    this.publishId,
  });

  final String provider;
  final String name;

  /// built lazily so a missing key only throws for the fixtures that need it
  final Future<http.Response> Function(Options options) request;

  /// false for the fixtures that deliberately provoke an error body
  final bool expectSuccess;

  /// only annotates the log, these run like any other fixture
  final bool createsOrder;

  /// runs in a second pass, after the create fixtures have published their ids
  final bool needsId;

  /// pulls the id of the thing just created out of the response, for the needsId fixture of the
  /// same provider. this is the only place a body is decoded, and only in memory - what lands on
  /// disk is still the exact bytes that came back
  final String? Function(String body)? publishId;
}

class Options {
  Options({required this.out});

  final String out;

  /// filled in during the run by the create fixtures
  final Map<String, String> ids = {};

  String id(String provider) => ids[provider]!;
}

final _client = http.Client();

Future<http.Response> _get(String url, {Map<String, String> headers = const {}}) =>
    _client.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 40));

Future<http.Response> _postJson(
  String url,
  Object body, {
  Map<String, String> headers = const {},
}) =>
    _client
        .post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json", ...headers},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 40));

/// digs a value out of a response body so a status fixture can chain off a create. only ever
/// looks at an in memory copy, the fixture itself is written verbatim
String? _pick(String body, List<String> path) {
  try {
    Object? node = json.decode(body);
    for (final key in path) {
      if (node is! Map<String, dynamic>) {
        return null;
      }
      node = node[key];
    }
    return node?.toString();
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// stealthex - https://api.stealthex.io, Authorization header
// ---------------------------------------------------------------------------

Map<String, String> _stealthExHeaders() =>
    {"Authorization": _requireKey("stealthExBearerToken", secrets.stealthExBearerToken)};

Map<String, Object> _stealthExRoute() => {
      "route": {
        "from": {"symbol": "btc", "network": "mainnet"},
        "to": {"symbol": "xmr", "network": "mainnet"},
      },
      "estimation": "direct",
      "rate": "floating",
    };

List<Fixture> _stealthEx() => [
      Fixture("stealthex", "rates_range", (_) => _postJson(
          "https://api.stealthex.io/v4/rates/range",
          _stealthExRoute(),
          headers: _stealthExHeaders(),
        )),
      Fixture("stealthex", "rates_estimated_amount", (_) => _postJson(
          "https://api.stealthex.io/v4/rates/estimated-amount",
          {..._stealthExRoute(), "amount": 0.01},
          headers: _stealthExHeaders(),
        )),
      // no route for this pair, for the 404 err body
      Fixture("stealthex", "rates_range_no_pair", (_) => _postJson(
          "https://api.stealthex.io/v4/rates/range",
          {
            "route": {
              "from": {"symbol": "btc", "network": "mainnet"},
              "to": {"symbol": "nosuchcoin", "network": "mainnet"},
            },
            "estimation": "direct",
            "rate": "floating",
          },
          headers: _stealthExHeaders(),
        ), expectSuccess: false),
      Fixture("stealthex", "exchange", (options) => _get(
          'https://api.stealthex.io/v4/exchanges/${options.id('stealthex')}',
          headers: _stealthExHeaders(),
        ), needsId: true),
      Fixture("stealthex", "create_exchange", (options) => _postJson(
          "https://api.stealthex.io/v4/exchanges",
          {
            "route": {
              "from": {"symbol": "eth", "network": "mainnet"},
              "to": {"symbol": "usdt", "network": "eth"},
            },
            "estimation": "direct",
            "rate": "floating",
            "amount": 0.01,
            "address": _ethAddress,
            "refund_address": _ethAddress,
          },
          headers: _stealthExHeaders(),
        ), createsOrder: true, publishId: (body) => _pick(body, ["id"])),
    ];

// ---------------------------------------------------------------------------
// xoswap - https://exchange.exodus.io, App-Name header, no api key
// ---------------------------------------------------------------------------

const _xoSwapHeaders = {"Content-Type": "application/json", "App-Name": "cake-labs"};

List<Fixture> _xoSwap() => [
      Fixture("xoswap", "assets", (_) => _get(
          "https://exchange.exodus.io/v3/assets?networks=ethereum&query=USDT",
          headers: _xoSwapHeaders,
        )),
      Fixture("xoswap", "pair_rates", (_) => _get(
          "https://exchange.exodus.io/v3/pairs/BTC_ETH/rates",
          headers: _xoSwapHeaders,
        )),
      Fixture("xoswap", "order", (options) => _get(
          'https://exchange.exodus.io/v3/orders/${options.id('xoswap')}',
          headers: _xoSwapHeaders,
        ), needsId: true),
      Fixture("xoswap", "create_order", (options) => _postJson(
          "https://exchange.exodus.io/v3/orders",
          {
            "pairId": "ETH_USDT",
            "fromAmount": "0.1",
            "fromAddress": _ethAddress,
            "toAmount": "30",
            "toAddress": _ethAddress,
          },
          headers: _xoSwapHeaders,
        ), createsOrder: true, publishId: (body) => _pick(body, ["id"])),
    ];


// ---------------------------------------------------------------------------
// trocador - https://api.trocador.app, API-Key header
// ---------------------------------------------------------------------------

Map<String, String> _trocadorHeaders() =>
    {"API-Key": _requireKey("trocadorApiKey", secrets.trocadorApiKey)};

String get _trocadorMarkup =>
    secrets.trocadorExchangeMarkup.trim().isEmpty ? "0" : secrets.trocadorExchangeMarkup;

List<Fixture> _trocador() => [
      Fixture("trocador", "coin", (_) => _get(
          "https://api.trocador.app/coin?ticker=btc&name=Bitcoin",
          headers: _trocadorHeaders(),
        )),
      Fixture("trocador", "new_rate", (_) => _get(
          "https://api.trocador.app/new_rate"
          "?ticker_from=btc&ticker_to=xmr&network_from=Mainnet&network_to=Mainnet"
          "&amount_from=0.01&payment=False&min_kycrating=C&markup=$_trocadorMarkup",
          headers: _trocadorHeaders(),
        )),
      Fixture("trocador", "exchanges", (_) => _get(
          "https://api.trocador.app/exchanges"
          '?api_key=${_requireKey('trocadorApiKey', secrets.trocadorApiKey)}',
        )),
      Fixture("trocador", "trade", (options) => _get(
          'https://api.trocador.app/trade?id=${options.id('trocador')}',
          headers: _trocadorHeaders(),
        ), needsId: true),
      Fixture("trocador", "new_trade", (options) => _get(
          "https://api.trocador.app/new_trade"
          "?ticker_from=eth&ticker_to=usdt&network_from=ERC20&network_to=ERC20"
          "&amount_from=0.01&payment=False&min_kycrating=C&markup=$_trocadorMarkup"
          "&address=$_ethAddress&refund=$_ethAddress"
          "&refund_memo=0",
          headers: _trocadorHeaders(),
        ), createsOrder: true, publishId: (body) => _pick(body, ["trade_id"])),
    ];

// ---------------------------------------------------------------------------
// swaptrade - https://api.swaptrade.io, no api key
// ---------------------------------------------------------------------------

List<Fixture> _swapTrade() => [
      Fixture("swaptrade", "get_coins", (_) => _get("https://api.swaptrade.io/api/swap/get-coins")),
      Fixture("swaptrade", "get_rate", (_) => _postJson("https://api.swaptrade.io/api/swap/get-rate", {
          "coin_send": "BTC",
          "coin_receive": "XMR",
          "amount": "0.01",
          "ref": "cake",
        })),
      // an unsupported pair answers 200 with price "NaN"
      Fixture("swaptrade", "get_rate_unknown_pair", (_) => _postJson("https://api.swaptrade.io/api/swap/get-rate", {
          "coin_send": "NOPECOIN",
          "coin_receive": "XMR",
          "amount": "0.01",
        })),
      // empty body, for the {success: false, errors: [...]} envelope. swaptrade answers 200 and
      // puts the real status in the body, so this one does expect a 2xx
      Fixture("swaptrade", "order_bad_request", (_) => _postJson("https://api.swaptrade.io/api/swap/order", const <String, Object>{})),
      Fixture("swaptrade", "order", (options) => _postJson("https://api.swaptrade.io/api/swap/order", {
          "order_id": options.id("swaptrade"),
        }), needsId: true),
      Fixture("swaptrade", "create_order", (options) => _postJson("https://api.swaptrade.io/api/swap/create-order", {
          "coin_send": "ETH",
          "coin_send_network": "ETH",
          "coin_receive": "USDT",
          "coin_receive_network": "USDT_ERC20",
          "amount_send": "100.01",
          "recipient": _ethAddress,
          "refund_address": _ethAddress,
          "ref": "cake",
          "markup": double.tryParse(secrets.swapTradeExchangeMarkup) ?? 0,
        }), createsOrder: true, publishId: (body) => _pick(body, ["data", "order_id"])),
    ];

// ---------------------------------------------------------------------------
// jupiter - https://api.jup.ag, x-api-key header. /ultra/v1/execute is never called here,
// it broadcasts a transaction
// ---------------------------------------------------------------------------

Map<String, String> _jupiterHeaders() =>
    {"x-api-key": _requireKey("jupiterApiKey", secrets.jupiterApiKey)};

String get _jupiterReferral {
  const account = secrets.jupiterReferralAccount;
  const fee = secrets.jupiterReferralFeeBps;
  if (account.trim().isEmpty || fee.trim().isEmpty) {
    return "";
  }
  return "&referralAccount=$account&referralFee=$fee";
}

List<Fixture> _jupiter() => [
      // no taker: a quote, with no transaction, no fees and no slippage estimate
      Fixture("jupiter", "order_quote", (_) => _get(
          "https://api.jup.ag/ultra/v1/order"
          "?inputMint=$_solMint&outputMint=$_usdcMint&amount=100000000",
          headers: _jupiterHeaders(),
        )),
      // with a taker the fee breakdown and slippage are filled in. an address with no balance
      // answers 200 with errorCode 1, which is a fixture worth having either way
      Fixture("jupiter", "order_with_taker", (_) => _get(
          "https://api.jup.ag/ultra/v1/order"
          "?inputMint=$_solMint&outputMint=$_usdcMint&amount=100000000"
          "&taker=$_solAddress$_jupiterReferral",
          headers: _jupiterHeaders(),
        )),
      Fixture("jupiter", "order_bad_amount", (_) => _get(
          "https://api.jup.ag/ultra/v1/order"
          "?inputMint=$_solMint&outputMint=$_usdcMint&amount=1",
          headers: _jupiterHeaders(),
        ), expectSuccess: false),
    ];

// ---------------------------------------------------------------------------
// near intents - https://1click.chaindefuser.com, bearer token
// ---------------------------------------------------------------------------

Map<String, String> _nearIntentsHeaders() => {
      "Authorization":
          'Bearer ${_requireKey('nearIntentsBearerToken', secrets.nearIntentsBearerToken)}',
    };

List<Object> _nearIntentsAppFees() {
  const recipient = secrets.nearIntentsAppFeeRecipient;
  final fee = int.tryParse(secrets.nearIntentsAppFee);
  if (recipient.trim().isEmpty || fee == null) {
    return const [];
  }
  return [
    {"recipient": recipient, "fee": fee},
  ];
}

Map<String, Object> _nearIntentsQuoteBody({required bool dry}) => {
      "dry": dry,
      "depositMode": "SIMPLE",
      "swapType": "EXACT_INPUT",
      "slippageTolerance": 100,
      // usdc on arbitrum into wnear. the recipient has to belong to the destination chain, and
      // the eth -> wnear pair we used before now answers "No liquidity available"
      "originAsset": "nep141:arb-0xaf88d065e77c8cc2239327c5edb3a432268e5831.omft.near",
      "depositType": "ORIGIN_CHAIN",
      "destinationAsset": "nep141:wrap.near",
      "amount": "10000000",
      "refundTo": _ethAddress,
      "refundType": "ORIGIN_CHAIN",
      "recipient": "cakewallet.near",
      "recipientType": "DESTINATION_CHAIN",
      "deadline": DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String(),
      if (_nearIntentsAppFees().isNotEmpty) "appFees": _nearIntentsAppFees(),
    };

List<Fixture> _nearIntents() => [
      // the token list needs no auth, so it works without the bearer token
      Fixture("nearintents", "tokens", (_) => _get("https://1click.chaindefuser.com/v0/tokens")),
      Fixture("nearintents", "quote_dry", (_) => _postJson(
          "https://1click.chaindefuser.com/v0/quote",
          _nearIntentsQuoteBody(dry: true),
          headers: _nearIntentsHeaders(),
        )),
      Fixture("nearintents", "quote_bad_request", (_) => _postJson(
          "https://1click.chaindefuser.com/v0/quote",
          const <String, Object>{},
          headers: _nearIntentsHeaders(),
        ), expectSuccess: false),
      Fixture("nearintents", "status", (options) => _get(
          "https://1click.chaindefuser.com/v0/status"
          '?depositAddress=${options.id('nearintents')}',
          headers: _nearIntentsHeaders(),
        ), needsId: true),
      // dry false allocates a real deposit address, which is this provider's create trade
      Fixture("nearintents", "quote_live", (_) => _postJson(
          "https://1click.chaindefuser.com/v0/quote",
          _nearIntentsQuoteBody(dry: false),
          headers: _nearIntentsHeaders(),
        ), createsOrder: true, publishId: (body) => _pick(body, ["quote", "depositAddress"])),
    ];

// ---------------------------------------------------------------------------
// swapsxyz - https://api-v2.swaps.xyz, x-api-key header. registerTxs is never called here,
// it mutates a trade
// ---------------------------------------------------------------------------

Map<String, String> _swapsXyzHeaders() =>
    {"x-api-key": _requireKey("swapsXyzApiKey", secrets.swapsXyzApiKey)};

List<Fixture> _swapsXyz() => [
      Fixture("swapsxyz", "chain_list", (_) => _get("https://api-v2.swaps.xyz/api/getChainList", headers: _swapsXyzHeaders())),
      Fixture("swapsxyz", "paths", (_) => _get(
          "https://api-v2.swaps.xyz/api/getPaths"
          "?srcChainId=1&srcToken=$_nativeEvmToken&dstChainId=137",
          headers: _swapsXyzHeaders(),
        )),
      Fixture("swapsxyz", "quote", (_) => _get(
          "https://api-v2.swaps.xyz/api/getQuote"
          "?swapDirection=exact-amount-in&srcToken=$_nativeEvmToken&srcChainId=1"
          "&dstToken=$_usdtErc20&dstChainId=1&amount=100000000000000000",
          headers: _swapsXyzHeaders(),
        )),
      // deliberately unauthenticated, for the {success: false, error: {...}} envelope
      Fixture("swapsxyz", "error_no_api_key", (_) => _get(
          "https://api-v2.swaps.xyz/api/getPaths?srcChainId=1&srcToken=$_nativeEvmToken",
        ), expectSuccess: false),
      // the txId from getAction is not queryable until the transaction is registered, and this
      // script never broadcasts one, so a 404 is the honest answer here
      Fixture("swapsxyz", "status", (options) => _get(
          'https://api-v2.swaps.xyz/api/getStatus?txId=${options.id('swapsxyz')}',
          headers: _swapsXyzHeaders(),
        ), needsId: true, expectSuccess: false),
      // returns an unsigned transaction plus a server side txId
      Fixture("swapsxyz", "action", (options) => _get(
          "https://api-v2.swaps.xyz/api/getAction"
          "?actionType=swap-action&sender=$_ethAddress"
          "&srcChainId=1&srcToken=$_nativeEvmToken&dstChainId=1&dstToken=$_usdtErc20"
          "&slippage=300&amount=100000000000000000&swapDirection=exact-amount-in"
          "&recipient=$_ethAddress",
          headers: _swapsXyzHeaders(),
        ), createsOrder: true, publishId: (body) => _pick(body, ["txId"])),
    ];

// ---------------------------------------------------------------------------
// chainflip - https://chainflip-broker.io, apiKey travels as a query param
// ---------------------------------------------------------------------------

String _chainflipKey() => _requireKey("chainflipApiKey", secrets.chainflipApiKey);

String get _chainflipCommission =>
    secrets.chainflipAffiliateFee.trim().isEmpty ? "0" : secrets.chainflipAffiliateFee;

List<Fixture> _chainflip() => [
      Fixture("chainflip", "assets", (_) => _get("https://chainflip-broker.io/assets")),
      Fixture("chainflip", "quotes_native", (_) => _get(
          "https://chainflip-broker.io/quotes-native"
          "?apiKey=${_chainflipKey()}&sourceAsset=btc.btc&destinationAsset=eth.eth"
          "&amount=10000000&commissionBps=$_chainflipCommission")),
      Fixture("chainflip", "quotes_native_bad_amount", (_) => _get(
          "https://chainflip-broker.io/quotes-native"
          "?apiKey=${_chainflipKey()}&sourceAsset=btc.btc&destinationAsset=eth.eth"
          "&amount=1&commissionBps=$_chainflipCommission"), expectSuccess: false),
      // the status query is composite, so pass the whole thing:
      // --id 'chainflip=issuedBlock=123&network=Bitcoin&channelId=45'
      Fixture("chainflip", "status_by_deposit_channel", (options) => _get(
          "https://chainflip-broker.io/status-by-deposit-channel"
          "?apiKey=${_chainflipKey()}&${options.id("chainflip")}"), needsId: true),
      // opens a real deposit channel
      Fixture("chainflip", "swap", (options) => _get(
          "https://chainflip-broker.io/swap"
          "?apiKey=${_chainflipKey()}&sourceAsset=eth.eth&destinationAsset=usdc.eth"
          "&destinationAddress=$_ethAddress"
          "&refundAddress=$_ethAddress"
          "&commissionBps=$_chainflipCommission&minimumPrice=0&retryDurationInBlocks=100"),
        createsOrder: true, publishId: (body) {
          final issuedBlock = _pick(body, ["issuedBlock"]);
          final network = _pick(body, ["network"]);
          final channelId = _pick(body, ["channelId"]);
          if (issuedBlock == null || network == null || channelId == null) {
            return null;
          }
          return "issuedBlock=$issuedBlock&network=$network&channelId=$channelId";
        }),
    ];

// ---------------------------------------------------------------------------
// changenow - https://api.changenow.io, x-changenow-api-key header
// ---------------------------------------------------------------------------

Map<String, String> _changeNowHeaders() => {
      "x-changenow-api-key":
          _requireKey("changeNowCakeWalletApiKey", secrets.changeNowCakeWalletApiKey),
    };

const _changeNowPair =
    "fromCurrency=btc&toCurrency=xmr&fromNetwork=btc&toNetwork=xmr&flow=standard";

List<Fixture> _changeNow() => [
      Fixture("changenow", "range", (_) => _get(
          "https://api.changenow.io/v2/exchange/range?$_changeNowPair",
          headers: _changeNowHeaders())),
      Fixture("changenow", "estimated_amount", (_) => _get(
          "https://api.changenow.io/v2/exchange/estimated-amount"
          "?$_changeNowPair&type=direct&fromAmount=0.01",
          headers: _changeNowHeaders())),
      Fixture("changenow", "estimated_amount_below_min", (_) => _get(
          "https://api.changenow.io/v2/exchange/estimated-amount"
          "?$_changeNowPair&type=direct&fromAmount=0.00000001",
          headers: _changeNowHeaders()), expectSuccess: false),
      Fixture("changenow", "by_id", (options) => _get(
          "https://api.changenow.io/v2/exchange/by-id?id=${options.id("changenow")}",
          headers: _changeNowHeaders()), needsId: true),
      Fixture("changenow", "create_exchange", (options) => _postJson(
          "https://api.changenow.io/v2/exchange",
          {
            "fromCurrency": "eth",
            "toCurrency": "usdt",
            "fromNetwork": "eth",
            "toNetwork": "eth",
            "fromAmount": "0.01",
            "address": _ethAddress,
            "refundAddress": _ethAddress,
            "flow": "standard",
            "type": "direct",
          },
          headers: _changeNowHeaders()), createsOrder: true, publishId: (body) => _pick(body, ["id"])),
    ];

// ---------------------------------------------------------------------------
// exolix - https://exolix.com, apiToken travels as a query param
// ---------------------------------------------------------------------------

String _exolixKey() =>
    _requireKey("exolixCakeWalletApiKey", secrets.exolixCakeWalletApiKey);

List<Fixture> _exolix() => [
      Fixture("exolix", "rate", (_) => _get(
          "https://exolix.com/api/v2/rate"
          "?coinFrom=BTC&coinTo=XMR&networkFrom=BTC&networkTo=XMR&rateType=float"
          "&amount=1&apiToken=${_exolixKey()}")),
      Fixture("exolix", "rate_fixed", (_) => _get(
          "https://exolix.com/api/v2/rate"
          "?coinFrom=BTC&coinTo=XMR&networkFrom=BTC&networkTo=XMR&rateType=fixed"
          "&amount=1&apiToken=${_exolixKey()}")),
      // under the minimum, exolix answers 200 with a message and the min in the body
      Fixture("exolix", "rate_below_min", (_) => _get(
          "https://exolix.com/api/v2/rate"
          "?coinFrom=BTC&coinTo=XMR&networkFrom=BTC&networkTo=XMR&rateType=float"
          "&amount=0.00000001&apiToken=${_exolixKey()}"), expectSuccess: false),
      Fixture("exolix", "transaction", (options) => _get(
          "https://exolix.com/api/v2/transactions/${options.id("exolix")}"), needsId: true),
      Fixture("exolix", "create_transaction", (options) => _postJson(
          "https://exolix.com/api/v2/transactions",
          {
            "coinFrom": "ETH",
            "coinTo": "USDT",
            "networkFrom": "ETH",
            "networkTo": "ETH",
            "amount": "0.01",
            "withdrawalAddress": _ethAddress,
            "refundAddress": _ethAddress,
            "rateType": "float",
            "apiToken": _exolixKey(),
          }), createsOrder: true, publishId: (body) => _pick(body, ["id"])),
    ];

// ---------------------------------------------------------------------------
// letsexchange - https://api.letsexchange.io, Authorization header, no Bearer prefix
// ---------------------------------------------------------------------------

Map<String, String> _letsExchangeHeaders() => {
      "Accept": "application/json",
      "Authorization": _requireKey("letsExchangeBearerToken", secrets.letsExchangeBearerToken),
    };

Map<String, Object> _letsExchangeInfoBody({required bool float}) => {
      "from": "BTC",
      "to": "XMR",
      "amount": "1",
      "affiliate_id": secrets.letsExchangeAffiliateId,
      "float": float,
    };

List<Fixture> _letsExchange() => [
      Fixture("letsexchange", "info", (_) => _postJson(
          "https://api.letsexchange.io/api/v1/info",
          _letsExchangeInfoBody(float: true),
          headers: _letsExchangeHeaders())),
      // the fixed rate variant, which is what supportsFixedRate uses
      Fixture("letsexchange", "info_revert", (_) => _postJson(
          "https://api.letsexchange.io/api/v1/info-revert",
          _letsExchangeInfoBody(float: false),
          headers: _letsExchangeHeaders())),
      Fixture("letsexchange", "info_bad_request", (_) => _postJson(
          "https://api.letsexchange.io/api/v1/info",
          const <String, Object>{},
          headers: _letsExchangeHeaders()), expectSuccess: false),
      Fixture("letsexchange", "transaction", (options) => _get(
          "https://api.letsexchange.io/api/v1/transaction/${options.id("letsexchange")}",
          headers: _letsExchangeHeaders()), needsId: true),
      Fixture("letsexchange", "create_transaction", (options) => _postJson(
          "https://api.letsexchange.io/api/v1/transaction",
          {
            "coin_from": "USDT",
            "coin_to": "USDC",
            "network_from": "ERC20",
            "network_to": "ERC20",
            "deposit_amount": "150",
            "withdrawal": _ethAddress,
            "withdrawal_extra_id": "",
            "return": _ethAddress,
            "affiliate_id": secrets.letsExchangeAffiliateId,
            "float": true,
          },
          headers: _letsExchangeHeaders()), createsOrder: true, publishId: (body) => _pick(body, ["transaction_id"])),
    ];



List<Fixture> _allFixtures() => [
      ..._chainflip(),
      ..._changeNow(),
      ..._exolix(),
      ..._letsExchange(),
      ..._stealthEx(),
      ..._xoSwap(),
      ..._trocador(),
      ..._swapTrade(),
      ..._jupiter(),
      ..._nearIntents(),
      ..._swapsXyz(),
    ];

Options _parseArgs(List<String> args) {
  var out = _defaultOut;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String next() {
      if (i + 1 >= args.length) {
        throw Exception("$arg needs a value");
      }
      return args[++i];
    }

    switch (arg) {
      case "--out":
        out = next();
      case "--help":
      case "-h":
        stdout.writeln(
          "usage: dart run tool/fetch_exchange_fixtures.dart\n"
          "  --out DIR  where to write (default $_defaultOut)\n",
        );
        exit(0);
      default:
        throw Exception('unknown argument "$arg", try --help');
    }
  }

  return Options(out: out);
}

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);

  final all = _allFixtures();
  // creates first, so their ids are on hand for the fixtures that look a trade up
  final fixtures = [...all.where((f) => !f.needsId), ...all.where((f) => f.needsId)];

  stdout.writeln("fetching ${fixtures.length} fixtures. the create endpoints register real orders, "
      "payout and refund go to $_ethAddress\n");

  final written = <String>[];
  final skipped = <String>[];
  final failed = <String>[];

  for (final fixture in fixtures) {
    final label = "${fixture.provider}/${fixture.name}";

    if (fixture.needsId && !options.ids.containsKey(fixture.provider)) {
      skipped.add("$label (no id, ${fixture.provider}'s create fixture did not return one)");
      stdout.writeln("  skip    $label - nothing was created to look up");
      continue;
    }

    try {
      final response = await fixture.request(options);
      final path = "${options.out}/${fixture.provider}/${fixture.name}.json";
      final file = File(path);
      await file.parent.create(recursive: true);
      // verbatim, no decode and no re-encode
      await file.writeAsString(response.body);

      final ok = response.statusCode >= 200 && response.statusCode < 300;
      final size = "${response.bodyBytes.length}B";
      if (ok == fixture.expectSuccess) {
        written.add("$label  ${response.statusCode} $size");
        final published = fixture.publishId?.call(response.body);
        if (published != null) {
          options.ids[fixture.provider] = published;
        }
        final note = fixture.createsOrder
            ? published == null
                ? " [${response.body}]"
                : " [created $published]"
            : "";
        stdout.writeln("  ok      $label -> $path (${response.statusCode}, $size)$note");
      } else {
        failed.add("$label  got ${response.statusCode}, expected "
            '${fixture.expectSuccess ? "2xx" : "an error"}');
        stdout.writeln("  huh     $label -> $path (${response.statusCode}, $size) "
            "- saved anyway, the body may still be a useful fixture\n${response.body}");
      }
    } on MissingApiKeyException catch (e) {
      skipped.add("$label ($e)");
      stdout.writeln("  skip    $label - $e");
    } catch (e) {
      failed.add("$label  $e");
      stdout.writeln("  failed  $label - $e");
    }

    // the providers rate limit, jupiter the most aggressively of them
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  _client.close();

  stdout.writeln("\nwrote ${written.length}, skipped ${skipped.length}, failed ${failed.length}");
  for (final s in skipped) {
    stdout.writeln("  skipped: $s");
  }
  for (final f in failed) {
    stdout.writeln("  failed:  $f");
  }

  exit(failed.isEmpty ? 0 : 1);
}
