import 'dart:convert';

import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import "package:cake_wallet/exchange/provider/thorchain/thorchain_api_schema.dart";
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cake_wallet/utils/exchange_provider_logger.dart';

class ThorChainExchangeProvider extends ExchangeProvider {
  ThorChainExchangeProvider();

  static final isRefundAddressSupported = [CryptoCurrency.eth];

  static const _baseNodeURL = 'thornode.ninerealms.com';
  static const _baseURL = 'midgard.ninerealms.com';
  static const _quotePath = '/thorchain/quote/swap';
  static const _txInfoPath = '/thorchain/tx/status/';
  static const _affiliateName = 'cakewallet';
  static const _affiliateBps = '175';
  static const _nameLookUpPath = 'v2/thorname/lookup/';

  @override
  String get title => 'THORChain';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  bool get supportsMemoOrDestinationTag => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.thorChain;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<ProviderRate> fetchRate(
      {required Money from, required bool isFixedRate, required CryptoCurrency to}) async {


    final responseData = await _getSwapQuote(ThorChainQuoteSwapRequest(
        fromAsset: from.currency as CryptoCurrency,
        toAsset: to,
        amount: ThorChainAmount.fromMoney(from),
        affiliate: _affiliateName,
        affiliateBps: _affiliateBps));

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(from, Money.parse(responseData.expectedAmountOut.toDouble(), to)),
      limits: ExchangeLimits(
        min: Money.tryParse(responseData.recommendedMinAmountIn, from.currency)
      )
    );
  }

  @override
  Future<ExchangeLimits> fetchLimits({required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode}) async =>
      (await fetchRate(from: Money(BigInt.from(1), from), to: to, isFixedRate: isFixedRateMode))
          .limits;

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
  }) async {
    final responseData = await _getSwapQuote(ThorChainQuoteSwapRequest(
        fromAsset: request.depositCurrency,
        toAsset: request.payoutCurrency,
        amount: ThorChainAmount.fromMoney(request.depositAmount.cryptoAmount),
        refundAddress: isRefundAddressSupported.contains(request.depositCurrency)
            ? _normalizeAddress(request.refundAddress)
            : "",
        destination: _normalizeAddress(request.payoutAddress.address),
        affiliate: _affiliateName,
        affiliateBps: _affiliateBps));

    return Trade(
      id: "",
      provider: description,
      refundAddress: request.refundAddress,
      fundingAddress: responseData.inboundAddress!,
      depositAmount: Money.parse(
          responseData.expectedAmountOut.toDouble(), request.depositCurrency),
      payoutAmount: request.payoutAmount.cryptoAmount,
      createdAt: DateTime.now(),
      state: TradeState.notFound,
      payoutAddress: request.payoutAddress.address,
      memo: responseData.memo,
    );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    if (id.isEmpty) throw Exception('Trade id is empty');
    final formattedId = id.startsWith('0x') ? id.substring(2) : id;
    final uri = Uri.https(_baseNodeURL, '$_txInfoPath$formattedId');
    final response = await ProxyWrapper().get(clearnetUri: uri);

    if (response.statusCode == 404) {
      throw Exception('Trade not found for id: $formattedId');
    } else if (response.statusCode != 200) {
      throw Exception('Unexpected HTTP status: ${response.statusCode}');
    }

    final responseJSON = ThorChainTxStatusResponse.fromJson(json.decode(response.body) as Map<String, dynamic>);
    final stagesJson = responseJSON.stages;

    final inboundObservedStarted = stagesJson.inboundObserved.started ?? true;
    if (!inboundObservedStarted) {
      throw Exception('Trade has not started for id: $formattedId');
    }


    final tx = responseJSON.tx;
    final coins = tx?.coins;
    final memo = tx?.memo;

    final parts = memo?.split(':') ?? [];

    final String toChain = parts.length > 1 ? parts[1].split('.')[0] : '';
    final String toAsset = parts.length > 1 && parts[1].split('.').length > 1
        ? parts[1].split('.')[1].split('-')[0]
        : '';

    final formattedToChain = CryptoCurrency.safeParseCurrencyFromString(toChain);
    final toAssetWithChain =
        CryptoCurrency.safeParseCurrencyFromString(toAsset, walletCurrency: formattedToChain);

    final isRefund = responseJSON.plannedOutTxs?.any((item)=>item.refund) ?? false;

    return Trade(
      id: id,
      refundAddress: "",
      depositAmount: Money.parse(tx?.coins.first.amount.toDouble()??0, tx!.coins.first.asset),
      payoutAmount: Money.zero(toAssetWithChain!),
      provider: description,
      fundingAddress: tx?.fromAddress ?? "",
      payoutAddress: tx?.toAddress ?? "",
      state: stagesJson.state,
      memo: memo,
      isRefund: isRefund,
    );
  }

  static Future<Map<String, String>?>? lookupAddressByName(String name) async {
    final uri = Uri.https(_baseURL, '$_nameLookUpPath$name');
    try {
      final response = await ProxyWrapper().get(clearnetUri: uri);

      if (response.statusCode != 200) {
        return null;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final entries = body['entries'] as List<dynamic>?;

      if (entries == null || entries.isEmpty) {
        return null;
      }

      Map<String, String> chainToAddressMap = {};

      for (final entry in entries) {
        final chain = entry['chain'] as String;
        final address = entry['address'] as String;
        chainToAddressMap[chain] = address;
      }

      return chainToAddressMap;
    } catch (e) {
      printV(e.toString());
      return null;
    }
  }

  Future<ThorChainQuoteSwapResponse> _getSwapQuote(ThorChainQuoteSwapRequest params) async {
    final uri = Uri.https(_baseNodeURL, _quotePath, params.toJson());

    final response = await ProxyWrapper().get(clearnetUri: uri);

    if (response.statusCode != 200) {
      throw Exception('Unexpected HTTP status: ${response.statusCode}');
    }

    if (response.body.contains('error')) {
      throw Exception('Unexpected response: ${response.body}');
    }

    return ThorChainQuoteSwapResponse.fromJson(json.decode(response.body) as Map<String, dynamic>);
  }

  String _normalizeAddress(String address) =>
      address.startsWith('bitcoincash:') ? address.replaceFirst('bitcoincash:', '') : address;
}
