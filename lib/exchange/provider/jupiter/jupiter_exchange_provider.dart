import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import "package:cake_wallet/exchange/provider/jupiter/jupiter_api_schema.dart";
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_not_created_exception.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/utils/exchange_provider_logger.dart';
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

class JupiterExchangeProvider extends ExchangeProvider {
  JupiterExchangeProvider();

  // Jupiter only supports Solana native SOL and Solana tokens
  bool _isSolanaCurrency(CryptoCurrency currency) =>
      currency == CryptoCurrency.sol || currency.tag == 'SOL';

  static const _baseUrl = 'api.jup.ag';
  static const _orderPath = '/ultra/v1/order';
  static const _executePath = '/ultra/v1/execute';
  static const _referralFee = secrets.jupiterReferralFeeBps;
  static const _referralAccount = secrets.jupiterReferralAccount;

  // Wrapped SOL address (native SOL)
  static const _nativeSolMint = 'So11111111111111111111111111111111111111112';

  @override
  String get title => 'Jupiter';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  bool get supportsMemoOrDestinationTag => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.jupiter;

  @override
  Future<bool> checkIsAvailable() async => true;

  String _getTokenMint(CryptoCurrency currency) {
    if (currency == CryptoCurrency.sol) return _nativeSolMint;

    if (currency.tag != 'SOL') {
      throw Exception('Unsupported currency: ${currency.title} (not a Solana token)');
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
      return ExchangeLimits(min: null, max: null);
    } else {
      throw Exception('not supported');
    }
  }

  Map<String, String> _getHeaders() => <String, String>{
      "x-api-key": secrets.jupiterApiKey
    };

  Map<String, String> _getReferralFeeConfig() =>  {
    'referralFee': secrets.jupiterReferralFeeBps,
    'referralAccount': secrets.jupiterReferralAccount,
  };

  @override
  Future<ProviderRate> fetchRate({
    required Money from,
    required CryptoCurrency to,
    required bool isFixedRate,
  }) async {
      // must support both
      if (!_isSolanaCurrency(from.currency as CryptoCurrency) || !_isSolanaCurrency(to)) {
        throw Exception("unsupported");
      }
      final inputMint = _getTokenMint(from.currency as CryptoCurrency);
      final outputMint = _getTokenMint(to);

      final params = JupiterOrderRequest(
          inputMint: inputMint, outputMint: outputMint, amount: from.amount);
      final uri = Uri.https(_baseUrl, _orderPath, params.toJson());
      final headers = _getHeaders();

      final response = await ProxyWrapper().get(
        clearnetUri: uri,
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception("status code: ${response.statusCode}");
      }

      final orderData = JupiterOrder.fromJson(json.decode(response.body) as Map<String, dynamic>);
      final outAmount = orderData.outAmount;

      return ProviderRate(provider: description, rate: ExchangeRate.fromAmounts(from, Money(outAmount, to)), limits: ExchangeLimits());

  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
  }) async {
      // must support both
      if (!_isSolanaCurrency(request.depositCurrency) || !_isSolanaCurrency(request.payoutCurrency)) {
        throw Exception('not supported currencies');
      }

      final inputMint = _getTokenMint(request.depositCurrency);
      final outputMint = _getTokenMint(request.payoutCurrency);


      final isInternalTransfer = request.refundAddress == request.payoutAddress.address;

      final orderParams = JupiterOrderRequest(
        inputMint: inputMint,
        outputMint: outputMint,
        amount: request.depositAmount.cryptoAmount.amount,
        taker: request.refundAddress,
        receiver: isInternalTransfer ? null : request.payoutAddress.address,
        referralFee: _referralFee,
        referralAccount: _referralAccount,);


      final orderUri = Uri.https(_baseUrl, _orderPath, orderParams.toJson());
      final headers = _getHeaders();

      final orderResponse = await ProxyWrapper().get(clearnetUri: orderUri, headers: headers);

      if (orderResponse.statusCode != 200) {
        throw TradeNotCreatedException(description, description: "status code: ${orderResponse.statusCode}");
      }

      final orderData = JupiterOrder.fromJson(json.decode(orderResponse.body) as Map<String, dynamic>);

      if (orderData.errorCode != null || orderData.errorMessage != null) {
        throw TradeNotCreatedException(description, description: "error code: ${orderData.errorCode}, error message: ${orderData.errorMessage}");
      }

      // Extract response data
      final transaction = orderData['transaction'] as String?;
      final requestId = orderData['requestId'] as String?;
      final outAmount = orderData['outAmount'] as String? ?? '0.0';

      // Extract network fees from order response (in lamports)
      final signatureFeeLamports = (orderData['signatureFeeLamports'] as num?)?.toInt() ?? 0;

      final prioritizationFeeLamports =
          (orderData['prioritizationFeeLamports'] as num?)?.toInt() ?? 0;

      final rentFeeLamports = (orderData['rentFeeLamports'] as num?)?.toInt() ?? 0;

      final integratorFeeLamports = (orderData['integratorFeeLamports'] as num?)?.toInt() ?? 0;

      final networkFeeLamports = signatureFeeLamports + prioritizationFeeLamports + rentFeeLamports;
      final networkFeeInSol = networkFeeLamports / 1000000000.0;

      final integratorFeeInSol = integratorFeeLamports / 1000000000.0;

      final totalFeeInSol = networkFeeInSol + integratorFeeInSol;

      if (transaction == null || transaction.isEmpty) {
        throw Exception('No transaction returned from Jupiter order endpoint');
      }

      if (requestId == null || requestId.isEmpty) {
        throw Exception('No requestId returned from Jupiter order endpoint');
      }

      final receiveAmount = AmountConverter.fromBaseUnits(outAmount, request.toCurrency.decimals);


      return Trade(
        id: requestId,
        from: request.fromCurrency,
        to: request.toCurrency,
        provider: description,
        inputAddress: request.toAddress,
        refundAddress: request.refundAddress,
        state: TradeState.created,
        createdAt: DateTime.now(),
        amount: request.fromAmount,
        receiveAmount: receiveAmount,
        payoutAddress: request.toAddress,
        isSendAll: isSendAll,
        routerData: transaction,
        routerValue: requestId,
        fee: totalFeeInSol,
      );
  }

  /// Executes a signed Jupiter swap transaction via Jupiter's /execute endpoint
  Future<Map<String, dynamic>> executeSwap({
    required String signedTransaction,
    required String requestId,
  }) async {
    try {
      final executeUri = Uri.https(_baseUrl, _executePath);
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';

      final body = json.encode({
        'signedTransaction': signedTransaction,
        'requestId': requestId,
      });

      final response = await ProxyWrapper().post(
        clearnetUri: executeUri,
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        ExchangeProviderLogger.logError(
          provider: description,
          function: 'executeSwap',
          error: Exception('Failed to execute swap: ${response.statusCode} $errorBody'),
          stackTrace: StackTrace.current,
          requestData: {
            'requestId': requestId,
            'hasSignedTransaction': signedTransaction.isNotEmpty,
          },
        );
        throw Exception('Failed to execute swap: ${response.statusCode} $errorBody');
      }

      final executeData = json.decode(response.body) as Map<String, dynamic>;

      ExchangeProviderLogger.logSuccess(
        provider: description,
        function: 'executeSwap',
        requestData: {
          'requestId': requestId,
          'hasSignedTransaction': signedTransaction.isNotEmpty,
        },
        responseData: executeData,
      );

      return executeData;
    } catch (e, s) {
      ExchangeProviderLogger.logError(
        provider: description,
        function: 'executeSwap',
        error: e,
        stackTrace: s,
        requestData: {
          'requestId': requestId,
          'hasSignedTransaction': signedTransaction.isNotEmpty,
        },
      );
      rethrow;
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    // Jupiter Ultra Swap API doesn't track trades by our trade ID
    //
    // Status tracking options:
    // 1. Use /execute endpoint with requestId + signedTransaction (requires storing signed tx)
    // 2. Check on-chain via transaction signature (txId) after transaction is sent
    //
    // Current implementation: We track status on-chain via transaction signature
    // The txId field in Trade is set after the transaction is sent and can be
    // used to check transaction status via Solana RPC.
    //
    // Note: To use /execute endpoint for status polling, we would need to:
    // - Store the signed transaction (not currently stored)
    // - Use requestId from routerValue
    // - Poll /ultra/v1/execute with both signedTransaction and requestId
    //
    // For now, throw exception to indicate status must be checked on-chain
    throw Exception(
        'Jupiter trade status must be checked on-chain using transaction signature (txId). '
        'After transaction is sent, txId will contain the signature for status checking.');
  }
}
