import "dart:io";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_exceptions.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/changenow/changenow_api_schema.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_found_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/utils/distribution_info.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/amount/money_double.dart";
import "package:cw_core/crypto_currency.dart";

class ChangeNowExchangeProvider extends ExchangeProvider {
  ChangeNowExchangeProvider({required SettingsStore settingsStore, super.proxyWrapper})
    : _settingsStore = settingsStore,
      _lastUsedRateId = "";

  static final apiKey = isMoneroOnly
      ? secrets.changeNowMoneroApiKey
      : secrets.changeNowCakeWalletApiKey;
  static const apiAuthority = "api.changenow.io";
  static const apiHeaderKey = "x-changenow-api-key";

  final SettingsStore _settingsStore;
  String _lastUsedRateId;

  late final _api = ProviderApi(
    proxyWrapper,
    authority: apiAuthority,
    headers: {apiHeaderKey: apiKey},
    errorMessage: (json) => json["message"]?.toString(),
  );

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.changeNow;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    if (from.title == "USDC" && from.tag == "POLY") {
      throw Exception("Only Bridged USDC (USDC.e) is allowed in ChangeNow");
    }

    final responseData = await _api.send(
      ChangeNowRangeRequest(
        fromCurrency: _normalizeCurrency(from),
        toCurrency: _normalizeCurrency(to),
        fromNetwork: _networkFor(from),
        toNetwork: _networkFor(to),
        flow: isFixedRateMode ? ChangeNowFlow.fixedRate : ChangeNowFlow.standard,
      ),
    );
    if (responseData.maxAmount == 0) {
      return ExchangeLimits();
    }
    return ExchangeLimits(
      min: Money.trySafeParse(responseData.minAmount, from),
      max: Money.trySafeParse(responseData.maxAmount, from),
    );
  }

  @override
  Future<ProviderRate> fetchRate(RateRequest request) async {
    if (request.amount.isZero) {
      throw Exception("cannot fetch rate with zero amount");
    }

    final (fromAmount, toAmount) = switch (request) {
      FloatingRateRequest(:final depositAmount) => (depositAmount.toString(), null),
      FixedRateRequest(:final payoutAmount) => (null, payoutAmount.toString()),
    };

    final responseData = await _api.send(
      ChangeNowEstimatedAmountRequest(
        fromCurrency: _normalizeCurrency(request.depositCurrency),
        toCurrency: _normalizeCurrency(request.payoutCurrency),
        fromAmount: fromAmount,
        toAmount: toAmount,
        fromNetwork: _networkFor(request.depositCurrency),
        toNetwork: _networkFor(request.payoutCurrency),
        flow: request is FixedRateRequest ? ChangeNowFlow.fixedRate : ChangeNowFlow.standard,
        type: request is FixedRateRequest ? ChangeNowExchangeType.reverse : ChangeNowExchangeType.direct,
        useRateId: request is FixedRateRequest ? "true" : null,
      ),
    );

    if (responseData.rateId?.isNotEmpty ?? false) {
      _lastUsedRateId = responseData.rateId!;
    }

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(
        responseData.fromAmount.toMoney(request.depositCurrency),
        responseData.toAmount.toMoney(request.payoutCurrency),
      ),
      limits: await fetchLimits(
        from: request.depositCurrency,
        to: request.payoutCurrency,
        isFixedRateMode: request is FixedRateRequest,
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final distributionPath = await DistributionInfo.instance.getDistributionPath();
    final formattedAppVersion = int.tryParse(_settingsStore.appVersion.replaceAll(".", "")) ?? 0;
    final payload = ChangeNowCreateExchangePayload(
      app: isMoneroOnly ? "monerocom" : "cakewallet",
      device: Platform.operatingSystem,
      distribution: distributionPath,
      version: formattedAppVersion,
    );

    if (request.isFixedRate) {
      // since we schedule to calculate the rate every 5 seconds we need to ensure that
      // we have the latest rate id with the given inputs before creating the trade
      await fetchRate(request.rateRequest);
    }
    final responseJSON = await _api.send(ChangeNowCreateExchangeRequest(
      fromCurrency: _normalizeCurrency(request.depositCurrency),
      toCurrency: _normalizeCurrency(request.payoutCurrency),
      fromNetwork: _networkFor(request.depositCurrency),
      toNetwork: _networkFor(request.payoutCurrency),
      fromAmount: request.isFixedRate ? null : request.depositAmount.toString(),
      toAmount: request.isFixedRate ? request.payoutAmount.toString() : null,
      address: request.payoutAddress,
      refundAddress: request.refundAddress,
      extraId: request.toAddressExtraId,
      flow: request.isFixedRate ? ChangeNowFlow.fixedRate : ChangeNowFlow.standard,
      type: request.isFixedRate ? ChangeNowExchangeType.reverse : ChangeNowExchangeType.direct,
      payload: payload,
      rateId: request.isFixedRate ? _lastUsedRateId : null,
    ));

    return Trade(
      id: responseJSON.id,
      provider: description,
      fundingAddress: responseJSON.payinAddress,
      refundAddress: request.refundAddress,
      extraId: responseJSON.payinExtraId,
      createdAt: DateTime.now(),
      state: TradeState.created,
      toAddressExtraId: request.toAddressExtraId,
      depositAmount: responseJSON.fromAmount.toMoney(request.depositCurrency),
      payoutAmount: responseJSON.toAmount.toMoney(request.payoutCurrency),
      payoutAddress: request.payoutAddress,
    );
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    final responseJSON = await _api.send(
      ChangeNowByIdRequest(id: trade.id),
      mapError: (e) => switch (e.statusCode) {
        404 => TradeNotFoundException(trade.id, provider: description),
        400 => TradeNotFoundException(trade.id, provider: description, description: e.message),
        _ => null,
      },
    );

    return trade.copyWith(
        state: responseJSON.status,
        createdAt: responseJSON.createdAt,
        expiredAt: responseJSON.validUntil,
        extraId: responseJSON.payinExtraId,
        outputTransaction: responseJSON.payoutHash,
        depositAmount: responseJSON.amountFrom == null ? null : Money.safeParse(responseJSON.amountFrom, trade.depositCurrency),
        payoutAmount: responseJSON.amountTo == null ? null : Money.safeParse(responseJSON.amountTo, trade.payoutCurrency)
    );
  }

  String _networkFor(CryptoCurrency currency) =>
      currency.tag != null ? _normalizeTag(currency.tag!) : _normalizeTitleToNetwork(currency.title);

  String _normalizeTitleToNetwork(String title) => switch (title.toUpperCase()) {
    "XNO" => "nano",
    _ => title.toLowerCase(),
  };

  String _normalizeCurrency(CryptoCurrency currency) =>
      currency == CryptoCurrency.maticpoly ? "matic" : currency.title;

  String _normalizeTag(String tag) {
    switch (tag) {
      case "POLY":
      case "POL":
        return "matic";
      case "LN":
        return "lightning";
      case "AVAXC":
        return "cchain";
      case "ARB":
        return "arbitrum";
      case "ROB":
        return "hood";
      default:
        return tag.toLowerCase();
    }
  }
}
