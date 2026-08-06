import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/chainflip/chainflip_api_schema.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";

class ChainflipExchangeProvider extends ExchangeProvider {
  ChainflipExchangeProvider({super.proxyWrapper});

  static final List<CryptoCurrency> _supported = [
    CryptoCurrency.btc,
    CryptoCurrency.eth,
    CryptoCurrency.usdc,
    CryptoCurrency.usdterc20,
    CryptoCurrency.flip,
    CryptoCurrency.wbtc,
    CryptoCurrency.sol,
    CryptoCurrency.usdcsol,
    CryptoCurrency.usdtSol,
    CryptoCurrency.arbEth,
    CryptoCurrency.usdcArb,
    CryptoCurrency.usdtArb,
    CryptoCurrency.trx,
    CryptoCurrency.usdttrc20,
  ];

  static const _baseURL = "chainflip-broker.io";
  static const _assetsPath = "/assets";
  static const _quotePath = "/quotes-native";
  static const _swapPath = "/swap";
  static const _txInfoPath = "/status-by-deposit-channel";
  static const _affiliateBps = secrets.chainflipAffiliateFee;
  static const _affiliateKey = secrets.chainflipApiKey;

  @override
  String get title => "Chainflip";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  bool get supportsMemoOrDestinationTag => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.chainflip;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    if (!_supported.contains(from) || !_supported.contains(to)) {
      throw Exception("No rates found for $from to $to");
    }

    final assetsResponse = ChainflipAssetsResponse.fromJson(await _getAssets());

    final asset = assetsResponse.assets.firstWhere((item) => item.id == from);
    final minAmount = Money(asset.minimalAmountNative, from);

    if (minAmount.isZero) {
      throw Exception("No rates found for $from to $to");
    }

    return ExchangeLimits(min: minAmount);
  }

  @override
  Future<ProviderRate> fetchRate({
    required Money from,
    required bool isFixedRate,
    required CryptoCurrency to,
  }) async {
    if (!_supported.contains(from.currency) || !_supported.contains(to)) {
      throw Exception("unsupported");
    }

    final quoteParams = ChainflipFetchQuotesRequest(
      apiKey: _affiliateKey,
      sourceAsset: from.currency as CryptoCurrency,
      destinationAsset: to,
      amount: from.amount,
      commissionBps: _affiliateBps,
    );

    final bestQuote = await _getSwapQuote(quoteParams);

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(from, Money(bestQuote.egressAmountNative, to)),
      limits: await fetchLimits(
        from: from.currency as CryptoCurrency,
        to: to,
        isFixedRateMode: isFixedRate,
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    const maxSlippage = 2;

    final quoteParams = ChainflipFetchQuotesRequest(
      apiKey: _affiliateKey,
      sourceAsset: request.depositAmount.currency,
      destinationAsset: request.payoutAmount.currency,
      amount: request.depositAmount.cryptoAmount.amount,
      commissionBps: _affiliateBps,
    );

    final quote = await _getSwapQuote(quoteParams);
    final estimatedPrice = quote.estimatedPrice;
    final minimumPrice = estimatedPrice * (100 - maxSlippage) / 100;

    final swapParams = ChainflipSwapRequest(
      apiKey: _affiliateKey,
      sourceAsset: request.depositAmount.currency,
      destinationAsset: request.payoutAmount.currency,
      destinationAddress: request.payoutAddress,
      minimumPrice: minimumPrice.toString(),
      refundAddress: request.refundAddress,
      retryDurationInBlocks: 150,
      commissionBps: _affiliateBps,
      numberOfChunks: quote.numberOfChunks,
      chunkIntervalBlocks: quote.chunkIntervalBlocks,
    );

    final swapResponse = await _openDepositChannel(swapParams);

    final id =
        "${swapResponse.issuedBlock}-${swapResponse.network.name}-${swapResponse.channelId}";

    return Trade(
      id: id,
      provider: description,
      createdAt: DateTime.now(),
      state: TradeState.waiting,
      depositAmount: request.depositAmount.cryptoAmount,
      payoutAmount: request.payoutAmount.cryptoAmount,
      fundingAddress: swapResponse.address,
      payoutAddress: request.payoutAddress,
      refundAddress: request.refundAddress,
    );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
      final channelParts = id.split("-");
      final network = channelParts[1];
      final normalizedNetwork = _normalizeNetworkName(network);

      final statusParams = ChainflipStatusRequest(
        apiKey: _affiliateKey,
        issuedBlock: int.parse(channelParts[0]),
        network: ChainflipNetwork.values.byName(normalizedNetwork),
        channelId: int.parse(channelParts[2]),
      );

      final statusResponse = await _getStatus(statusParams);

      if (statusResponse == null) {
        throw Exception("Trade not found for id: $id");
      }

      final status = statusResponse.status;
      final currentState = status.state;

      final depositAmount = Money(status.deposit?.amountNative ?? BigInt.zero, status.sourceAsset);
      final receiveAmount = Money(
        status.swapEgress?.amountNative ?? BigInt.zero,
        status.destinationAsset,
      );
      final refundAmount = Money(
        status.refundEgress?.amountNative ?? BigInt.zero,
        status.sourceAsset,
      );
      final isRefund = status.refundEgress != null;
      final amount = isRefund ? refundAmount : receiveAmount;

      final newTrade = Trade(
        id: id,
        provider: description,
        state: currentState,
        outputTransaction: status.swapEgress?.transactionReference,
        isRefund: isRefund,
        depositAmount: depositAmount,
        payoutAmount: amount,
        fundingAddress: status.depositChannel?.depositAddress ?? "",
        payoutAddress: status.destinationAddress,
        refundAddress: "",
      );

      return newTrade;
  }

  String _normalizeNetworkName(String name) {
    final networkName = switch (name.toUpperCase()) {
      "BITCOIN" => "bitcoin",
      "ETHEREUM" => "ethereum",
      "ARBITRUM" => "arbitrum",
      "SOLANA" => "solana",
      "TRON" => "tron",
      "ASSETHUB" => "assethub",
      _ => name,
    };

    return networkName;
  }

  Future<Map<String, dynamic>> _getAssets() => _getRequest(_assetsPath, {});

  Future<ChainflipSwapResponse> _openDepositChannel(ChainflipSwapRequest params) async =>
      ChainflipSwapResponse.fromJson(await _getRequest(_swapPath, params.toJson()));

  Future<Map<String, dynamic>> _getRequest(String path, Map<String, dynamic> params) async {
    final uri = Uri.https(_baseURL, path, params);

    final response = await proxyWrapper.get(clearnetUri: uri);

    if ((response.statusCode != 200) || (response.body.contains("error"))) {
      throw Exception(
        "Unexpected response: ${response.statusCode} / ${uri.toString()} / ${response.body}",
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<ChainflipQuote> _getSwapQuote(ChainflipFetchQuotesRequest params) async {
    final uri = Uri.https(_baseURL, _quotePath, params.toJson());
    final response = await proxyWrapper.get(clearnetUri: uri);

    if(response.statusCode < 200 || response.statusCode > 299) {
      throw Exception("status code: ${response.statusCode}");
    }

    final quotes = ChainflipFetchQuotesResponse.fromJson(
      jsonDecode(response.body) as List<dynamic>,
    );
    return quotes.quotes.max;
  }

  Future<ChainflipStatusResponse?> _getStatus(ChainflipStatusRequest params) async {
    final uri = Uri.https(_baseURL, _txInfoPath, params.toJson());

    final response = await proxyWrapper.get(clearnetUri: uri);

    if (response.statusCode == 404) {
      return null;
    }

    if ((response.statusCode != 200) || (response.body.contains("error"))) {
      throw Exception(
        "Unexpected response: ${response.statusCode} / ${uri.toString()} / ${response.body}",
      );
    }

    return ChainflipStatusResponse.fromJson(
      await json.decode(response.body) as Map<String, dynamic>,
    );
  }
}
