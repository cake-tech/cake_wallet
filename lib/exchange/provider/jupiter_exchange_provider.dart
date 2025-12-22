import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_not_created_exception.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/utils/exchange_provider_logger.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

class JupiterExchangeProvider extends ExchangeProvider {
  JupiterExchangeProvider() : super(pairList: _getSupportedPairs());

  // Jupiter only supports Solana tokens
  static const List<CryptoCurrency> _notSupported = [];

  static List<ExchangePair> _getSupportedPairs() {
    // Only support Solana and Solana tokens
    final solanaCurrencies = CryptoCurrency.all
        .where((c) => c.tag == 'SOL' || c == CryptoCurrency.sol)
        .where((c) => !_notSupported.contains(c))
        .toList();

    final pairs = <ExchangePair>[];
    for (final from in solanaCurrencies) {
      for (final to in solanaCurrencies) {
        if (from != to) {
          pairs.add(ExchangePair(from: from, to: to, reverse: true));
        }
      }
    }
    return pairs;
  }

  static const _baseUrl = 'api.jup.ag';
  static const _orderPath = '/ultra/v1/order';

  // Wrapped SOL address (native SOL)
  static const _nativeSolMint = 'So11111111111111111111111111111111111111112';

  @override
  String get title => 'Jupiter';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false; // Jupiter doesn't support fixed rate

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.jupiter;

  @override
  Future<bool> checkIsAvailable() async => true;

  String _getTokenMint(CryptoCurrency currency) {
    // Handle native SOL
    if (currency == CryptoCurrency.sol) return _nativeSolMint;

    // Check if currency tag is SOL (indicating it's a Solana token)
    if (currency.tag != 'SOL') {
      throw Exception('Unsupported currency: ${currency.title} (not a Solana token)');
    }

    // Use solana proxy to get token address
    // The proxy will handle both SPLToken instances and CryptoCurrency
    // by searching through default tokens
    if (solana != null) {
      try {
        return solana!.getTokenAddress(currency);
      } catch (e) {
        printV('Error getting token address: $e');
        throw Exception('Unsupported currency: ${currency.title} (mint address not found: $e)');
      }
    }

    throw Exception('Unsupported currency: ${currency.title} (Solana proxy not available)');
  }

  @override
  Future<Limits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    try {
      // The Ultra Swap API doesn't have a dedicated limits endpoint
      // The /order endpoint validates amounts and returns error codes:
      // - errorCode 1: Insufficient funds
      // - errorCode 2: Top up SOL for gas
      // - errorCode 3: Minimum amount for gasless
      return Limits(
        min: 0.0001, // Minimum reasonable amount for Solana swaps
        max: 1000000.0, // High limit; actual max depends on liquidity
      );
    } catch (e) {
      printV('fetchLimits error: $e');
      throw Exception('Error fetching limits: $e');
    }
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{};
    final apiKey = secrets.jupiterApiKey;
    if (apiKey.isNotEmpty) {
      headers['x-api-key'] = apiKey;
    }

    return headers;
  }

  @override
  Future<double> fetchRate({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount,
  }) async {
    try {
      final inputMint = _getTokenMint(from);
      final outputMint = _getTokenMint(to);

      final amountInBaseUnits = AmountConverter.toBaseUnits(amount.toString(), from.decimals);

      final params = {
        'inputMint': inputMint,
        'outputMint': outputMint,
        'amount': amountInBaseUnits,
        // Note: taker is optional for quote-only requests
      };

      final uri = Uri.https(_baseUrl, _orderPath, params);
      final headers = _getHeaders();

      final response = await ProxyWrapper().get(
        clearnetUri: uri,
        headers: headers,
      );

      if (response.statusCode != 200) {
        ExchangeProviderLogger.logError(
          provider: description,
          function: 'fetchRate',
          error: Exception('Failed to fetch quote: ${response.statusCode}'),
          stackTrace: StackTrace.current,
          requestData: {
            'from': from.title,
            'to': to.title,
            'amount': amount,
            'isFixedRateMode': isFixedRateMode,
            'isReceiveAmount': isReceiveAmount,
          },
        );
        return 0.0;
      }

      final orderData = json.decode(response.body) as Map<String, dynamic>;
      final outAmount = BigInt.parse(orderData['outAmount'] as String);

      final outputAmount = AmountConverter.fromBaseUnits(outAmount.toString(), to.decimals);

      final rate = double.parse(outputAmount) / amount;

      ExchangeProviderLogger.logSuccess(
        provider: description,
        function: 'fetchRate',
        requestData: {
          'from': from.title,
          'to': to.title,
          'amount': amount,
          'isFixedRateMode': isFixedRateMode,
          'isReceiveAmount': isReceiveAmount,
        },
        responseData: {
          'rate': rate,
          'outputAmount': outputAmount,
        },
      );

      return rate;
    } catch (e, s) {
      ExchangeProviderLogger.logError(
        provider: description,
        function: 'fetchRate',
        error: e,
        stackTrace: s,
        requestData: {
          'from': from.title,
          'to': to.title,
          'amount': amount,
          'isFixedRateMode': isFixedRateMode,
          'isReceiveAmount': isReceiveAmount,
        },
      );
      printV('fetchRate error: $e');
      return 0.0;
    }
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode,
    required bool isSendAll,
  }) async {
    try {
      final inputMint = _getTokenMint(request.fromCurrency);
      final outputMint = _getTokenMint(request.toCurrency);

      final amountInBaseUnits =
          AmountConverter.toBaseUnits(request.fromAmount, request.fromCurrency.decimals);

      final orderParams = <String, String>{
        'inputMint': inputMint,
        'outputMint': outputMint,
        'amount': amountInBaseUnits,
        'taker': request.refundAddress, // Required to get transaction
        'receiver': request.toAddress, // Output token receiver
      };

      // To add custom fees if needed
      // try {
      //   final referralAccount = secrets.jupiterReferralAccount;
      //   if (referralAccount != null && referralAccount.isNotEmpty) {
      //     orderParams['referralAccount'] = referralAccount;
      //     final referralFee = secrets.jupiterReferralFee;
      //     if (referralFee != null && referralFee.isNotEmpty) {
      //       final feeBps = int.tryParse(referralFee);
      //       if (feeBps != null && feeBps >= 50 && feeBps <= 255) {
      //         orderParams['referralFee'] = feeBps.toString();
      //       }
      //     }
      //   }
      // } catch (_) { }

      final orderUri = Uri.https(_baseUrl, _orderPath, orderParams);
      final headers = _getHeaders();

      final orderResponse = await ProxyWrapper().get(clearnetUri: orderUri, headers: headers);

      if (orderResponse.statusCode != 200) {
        final errorBody = orderResponse.body;
        ExchangeProviderLogger.logError(
          provider: description,
          function: 'createTrade',
          error: Exception('Failed to get order: ${orderResponse.statusCode} $errorBody'),
          stackTrace: StackTrace.current,
          requestData: {
            'from': request.fromCurrency.title,
            'to': request.toCurrency.title,
            'fromAmount': request.fromAmount,
            'toAmount': request.toAmount,
            'toAddress': request.toAddress,
            'refundAddress': request.refundAddress,
            'isFixedRateMode': isFixedRateMode,
            'isSendAll': isSendAll,
          },
        );
        throw TradeNotCreatedException(description);
      }

      final orderData = json.decode(orderResponse.body) as Map<String, dynamic>;

      // Check for errors in response
      if (orderData.containsKey('errorCode') || orderData.containsKey('errorMessage')) {
        final errorCode = orderData['errorCode'];
        final errorMessage = orderData['errorMessage'] ?? 'Unknown error';
        ExchangeProviderLogger.logError(
          provider: description,
          function: 'createTrade',
          error: Exception('Order error: $errorCode - $errorMessage'),
          stackTrace: StackTrace.current,
          requestData: {
            'from': request.fromCurrency.title,
            'to': request.toCurrency.title,
            'fromAmount': request.fromAmount,
            'toAmount': request.toAmount,
            'toAddress': request.toAddress,
            'refundAddress': request.refundAddress,
            'isFixedRateMode': isFixedRateMode,
            'isSendAll': isSendAll,
          },
        );
        throw TradeNotCreatedException(description);
      }

      // Extract response data
      final transaction = orderData['transaction'] as String?;
      final requestId = orderData['requestId'] as String?;
      final outAmount = orderData['outAmount'] as String;

      // Extract actual fees from order response (in lamports)
      final signatureFeeLamports = (orderData['signatureFeeLamports'] as num?)?.toInt() ?? 0;

      final prioritizationFeeLamports =
          (orderData['prioritizationFeeLamports'] as num?)?.toInt() ?? 0;

      final rentFeeLamports = (orderData['rentFeeLamports'] as num?)?.toInt() ?? 0;

      // Convert total fees to SOL (1 SOL = 1e9 lamports)
      final totalFeeLamports = signatureFeeLamports + prioritizationFeeLamports + rentFeeLamports;
      final totalFeeInSol = totalFeeLamports / 1000000000.0;

      if (transaction == null || transaction.isEmpty) {
        throw Exception('No transaction returned from Jupiter order endpoint');
      }

      if (requestId == null || requestId.isEmpty) {
        throw Exception('No requestId returned from Jupiter order endpoint');
      }

      final receiveAmount = AmountConverter.fromBaseUnits(outAmount, request.toCurrency.decimals);

      // Generate a unique trade ID
      final tradeId = 'jupiter_${DateTime.now().millisecondsSinceEpoch}';

      ExchangeProviderLogger.logSuccess(
        provider: description,
        function: 'createTrade',
        requestData: {
          'from': request.fromCurrency.title,
          'to': request.toCurrency.title,
          'fromAmount': request.fromAmount,
          'toAmount': request.toAmount,
          'toAddress': request.toAddress,
          'refundAddress': request.refundAddress,
          'isFixedRateMode': isFixedRateMode,
          'isSendAll': isSendAll,
        },
        responseData: {
          'tradeId': tradeId,
          'receiveAmount': receiveAmount,
          'hasTransaction': transaction.isNotEmpty,
          'requestId': requestId,
        },
      );

      return Trade(
        id: tradeId,
        from: request.fromCurrency,
        to: request.toCurrency,
        provider: description,
        inputAddress: request.refundAddress,
        refundAddress: request.refundAddress,
        state: TradeState.created,
        createdAt: DateTime.now(),
        amount: request.fromAmount,
        receiveAmount: receiveAmount,
        payoutAddress: request.toAddress,
        isSendAll: isSendAll,
        userCurrencyFromRaw: '${request.fromCurrency.title}_${request.fromCurrency.tag ?? 'SOL'}',
        userCurrencyToRaw: '${request.toCurrency.title}_${request.toCurrency.tag ?? 'SOL'}',
        routerData: transaction,
        routerValue: requestId,
        memo: totalFeeInSol.toString(),
      );
    } catch (e, s) {
      ExchangeProviderLogger.logError(
        provider: description,
        function: 'createTrade',
        error: e,
        stackTrace: s,
        requestData: {
          'from': request.fromCurrency.title,
          'to': request.toCurrency.title,
          'fromAmount': request.fromAmount,
          'toAmount': request.toAmount,
          'toAddress': request.toAddress,
          'refundAddress': request.refundAddress,
          'isFixedRateMode': isFixedRateMode,
          'isSendAll': isSendAll,
        },
      );
      printV('createTrade error: $e');
      throw TradeNotCreatedException(description);
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
