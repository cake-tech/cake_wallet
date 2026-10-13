import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/jupiter/jupiter_api_schema.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_created_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/utils/exchange_provider_logger.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/wallet_base.dart";

class JupiterTrade extends RoutableTrade {
  JupiterTrade({
    required this.fee,
    required super.state,
    required super.depositAmount,
    required super.payoutAmount,
    required super.id,
    required super.provider,
    required super.payoutAddress,
    required super.refundAddress,

    required super.routerData,
    required super.routerValue,
    super.router,
    super.createdAt,
    super.expiredAt,
    super.extraId,
    super.outputTransaction,
    super.walletId,
    super.toAddressExtraId,
    super.password,
    super.providerId,
    super.memo,
    super.txId,
    super.isRefund,
  }) : super(fundingAddress: "");

  final Money fee;
}

class JupiterExchangeProvider extends ExchangeProvider
    implements TransactionCreationExchangeProvider {
  JupiterExchangeProvider({super.proxyWrapper});

  // Jupiter only supports Solana native SOL and Solana tokens
  bool _isSolanaCurrency(CryptoCurrency currency) =>
      currency == CryptoCurrency.sol || currency.tag == "SOL";

  static const _baseUrl = "api.jup.ag";
  static const _referralFee = secrets.jupiterReferralFeeBps;
  static const _referralAccount = secrets.jupiterReferralAccount;
  static final _hasReferral = _referralFee.isNotEmpty && _referralAccount.isNotEmpty;

  late final _api = ProviderApi(
    proxyWrapper,
    authority: _baseUrl,
    headers: {"x-api-key": secrets.jupiterApiKey},
    errorMessage: (json) => json["error"]?.toString(),
  );

  // Wrapped SOL address (native SOL)
  static const _nativeSolMint = "So11111111111111111111111111111111111111112";

  @override
  bool get supportsFixedRate => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.jupiter;

  String _getTokenMint(CryptoCurrency currency) {
    if (currency == CryptoCurrency.sol) {
      return _nativeSolMint;
    }

    if (currency.tag != "SOL") {
      throw Exception("Unsupported currency: ${currency.title} (not a Solana token)");
    }

    return solana!.getTokenAddress(currency);
  }

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    // The Ultra Swap API doesn't have a dedicated limits endpoint
    // The /order endpoint validates amounts and returns error codes:
    // - errorCode 1: Insufficient funds
    // - errorCode 2: Top up SOL for gas
    // - errorCode 3: Minimum amount for gasless

    // only return null for supported currencies
    if (_isSolanaCurrency(from) && _isSolanaCurrency(to)) {
      return ExchangeLimits();
    } else {
      throw Exception("not supported");
    }
  }

  @override
  Future<ProviderRate> fetchRate(RateRequest request) async {
    if (request is! FloatingRateRequest) {
      throw Exception("fixed rate unsupported");
    }

    // must support both
    if (!_isSolanaCurrency(request.depositCurrency) || !_isSolanaCurrency(request.payoutCurrency)) {
      throw Exception("unsupported");
    }
    final inputMint = _getTokenMint(request.depositCurrency);
    final outputMint = _getTokenMint(request.payoutCurrency);

    final orderData = await _api.send(
      JupiterOrderRequest(
        inputMint: inputMint,
        outputMint: outputMint,
        amount: request.depositAmount.amount,
      ),
    );
    final outAmount = orderData.outAmount;

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(
        request.depositAmount,
        Money(outAmount, request.payoutCurrency),
      ),
      limits: ExchangeLimits(),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    // must support both
    if (!_isSolanaCurrency(request.depositCurrency) || !_isSolanaCurrency(request.payoutCurrency)) {
      throw Exception("not supported currencies");
    }

    final inputMint = _getTokenMint(request.depositCurrency);
    final outputMint = _getTokenMint(request.payoutCurrency);

    final isInternalTransfer = request.refundAddress == request.payoutAddress;

    final orderData = await _api.send(
      JupiterOrderRequest(
        inputMint: inputMint,
        outputMint: outputMint,
        amount: request.depositAmount.amount,
        taker: request.refundAddress,
        receiver: isInternalTransfer ? null : request.payoutAddress,
        referralFee: _hasReferral ? _referralFee : null,
        referralAccount: _hasReferral ? _referralAccount : null,
      ),
      mapError: (e) => TradeNotCreatedException(description, description: e.message),
    );

    if (orderData.errorCode != null || orderData.errorMessage != null) {
      throw TradeNotCreatedException(
        description,
        description: "error code: ${orderData.errorCode}, error message: ${orderData.errorMessage}",
      );
    }

    return JupiterTrade(
      id: orderData.requestId,
      provider: description,
      refundAddress: request.refundAddress,
      state: TradeState.created,
      createdAt: DateTime.now(),
      payoutAddress: request.payoutAddress,
      routerData: orderData.transaction!,
      routerValue: orderData.requestId,
      fee: Money.fromInt(orderData.totalFee, CryptoCurrency.sol),
      depositAmount: Money(orderData.inAmount, request.depositCurrency),
      payoutAmount: Money(orderData.outAmount, request.payoutCurrency),
    );
  }

  /// Executes a signed Jupiter swap transaction via Jupiter's /execute endpoint
  Future<JupiterExecuteResponse> executeSwap({
    required String signedTransaction,
    required String requestId,
  }) => _api.send(
    JupiterExecuteRequest(signedTransaction: signedTransaction, requestId: requestId),
    mapError: (e) => Exception("Failed to execute swap: ${e.message}"),
  );

  // the order's transaction carries a recent blockhash, so it can't land once that expires
  // (~150 slots). an order that still has no signature by then was never executed
  static const _orderTtl = Duration(minutes: 5);

  @override
  Future<Trade> updateTrade(Trade trade) async {
    final txId = trade.txId;

    if (txId == null || txId.isEmpty) {
      final createdAt = trade.createdAt;
      final isStale = createdAt == null || DateTime.now().difference(createdAt) > _orderTtl;
      return isStale ? trade.copyWith(state: TradeState.expired) : trade;
    }

    if (trade.state == TradeState.completed || trade.state == TradeState.failed) {
      return trade;
    }

    return trade.copyWith(
      state: switch (await solana!.getTransactionResult(txId)) {
        true => TradeState.completed,
        false => TradeState.failed,
        null => TradeState.processing,
      },
    );
  }

  @override
  Future<PendingTransaction> createTransaction(WalletBase wallet, Trade trade) {
    trade as JupiterTrade;

    return solana!.signAndPrepareJupiterSwapTransaction(
      wallet,
      trade.routerData,
      trade.routerValue,
      trade.payoutAddress,
      trade.depositAmount,
      trade.fee,
    );
  }
}
