import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/chainflip/chainflip_api_schema.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

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
  static const _affiliateBps = secrets.chainflipAffiliateFee;
  static const _affiliateKey = secrets.chainflipApiKey;

  late final _api = ProviderApi(
    proxyWrapper,
    authority: _baseURL,
    errorMessage: (json) => (json["detail"] ?? json["title"])?.toString(),
  );

  @override
  bool get supportsFixedRate => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.chainflip;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    if (!_supported.contains(from) || !_supported.contains(to)) {
      throw Exception("No rates found for $from to $to");
    }

    final assetsResponse = await _api.send(const ChainflipAssetsRequest());

    final asset = assetsResponse.assets.firstWhere((item) => item.id == from);
    final minAmount = Money(asset.minimalAmountNative, from);

    if (minAmount.isZero) {
      throw Exception("No rates found for $from to $to");
    }

    return ExchangeLimits(min: minAmount);
  }

  @override
  Future<ProviderRate> fetchRate(RateRequest request) async {
    if (request is! FloatingRateRequest) {
      throw Exception("fixed rate unsupported");
    }

    if (!_supported.contains(request.depositCurrency) || !_supported.contains(request.payoutCurrency)) {
      throw Exception("unsupported");
    }

    final quoteParams = ChainflipFetchQuotesRequest(
      apiKey: _affiliateKey,
      sourceAsset: request.depositCurrency,
      destinationAsset: request.payoutCurrency,
      amount: request.depositAmount.amount,
      commissionBps: _affiliateBps,
    );

    final bestQuote = (await _api.send(quoteParams)).quotes.max;

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(
        request.depositAmount,
        Money(bestQuote.egressAmountNative, request.payoutCurrency),
      ),
      limits: await fetchLimits(
        from: request.depositCurrency,
        to: request.payoutCurrency,
        isFixedRateMode: false,
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    const maxSlippage = 2;

    final quoteParams = ChainflipFetchQuotesRequest(
      apiKey: _affiliateKey,
      sourceAsset: request.depositCurrency,
      destinationAsset: request.payoutCurrency,
      amount: request.depositAmount.amount,
      commissionBps: _affiliateBps,
    );

    final quote = (await _api.send(quoteParams)).quotes.max;
    final estimatedPrice = quote.estimatedPrice;
    final minimumPrice = estimatedPrice * (100 - maxSlippage) / 100;

    final swapParams = ChainflipSwapRequest(
      apiKey: _affiliateKey,
      sourceAsset: request.depositCurrency,
      destinationAsset: request.payoutCurrency,
      destinationAddress: request.payoutAddress,
      minimumPrice: minimumPrice.toString(),
      refundAddress: request.refundAddress,
      retryDurationInBlocks: 150,
      commissionBps: _affiliateBps,
      numberOfChunks: quote.numberOfChunks,
      chunkIntervalBlocks: quote.chunkIntervalBlocks,
    );

    final swapResponse = await _api.send(swapParams);

    return Trade(
      id: "${swapResponse.issuedBlock}-${swapResponse.network.name}-${swapResponse.channelId}",
      provider: description,
      createdAt: DateTime.now(),
      state: TradeState.waiting,
      depositAmount: request.depositAmount,
      payoutAmount: request.payoutAmount,
      fundingAddress: swapResponse.address,
      payoutAddress: request.payoutAddress,
      refundAddress: request.refundAddress,
    );
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
      final channelParts = trade.id.split("-");
      final network = channelParts[1];
      final normalizedNetwork = network.toLowerCase();

      final statusParams = ChainflipStatusRequest(
        apiKey: _affiliateKey,
        issuedBlock: int.parse(channelParts[0]),
        network: ChainflipNetwork.values.byName(normalizedNetwork),
        channelId: int.parse(channelParts[2]),
      );

      final statusResponse = await _api.send(
        statusParams,
        mapError: (e) => switch (e.statusCode) {
          404 => Exception("Trade not found for id: ${trade.id}"),
          _ => null,
        },
      );

      return trade.copyWith(
        state: statusResponse.status.state.toState,
        outputTransaction: statusResponse.status.swapEgress?.transactionReference,
        isRefund: statusResponse.status.refundEgress != null,
        fundingAddress: statusResponse.status.depositChannel?.depositAddress,
        payoutAddress: statusResponse.status.destinationAddress,
      );

  }
}
