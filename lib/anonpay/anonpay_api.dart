import 'dart:convert';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/anonpay/anonpay_provider_description.dart';
import 'package:cake_wallet/anonpay/anonpay_request.dart';
import 'package:cake_wallet/anonpay/anonpay_status_response.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:http/http.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

class AnonPayApi {
  const AnonPayApi({
    this.useTorOnly = false,
    required this.wallet,
  });
  final bool useTorOnly;
  final WalletBase wallet;

  static const anonpayRef = secrets.anonPayReferralCode;
  static const onionApiAuthority = 'trocadorfyhlu27aefre5u7zri66gudtzdyelymftvr4yjwcxhfaqsid.onion';
  static const clearNetAuthority = 'trocador.app';
  static const markup = secrets.trocadorExchangeMarkup;
  static const anonPayPath = '/anonpay';
  static const anonPayStatus = '/anonpay/status';
  static const coinPath = 'api/coin';
  static const apiKey = secrets.trocadorApiKey;

  Future<AnonpayStatusResponse> paymentStatus(String id) async {
    final authority = await _getAuthority();
    final response = await get(Uri.https(authority, "$anonPayStatus/$id"));
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final status = responseJSON['Status'] as String;
    final fiatAmount = responseJSON['Fiat_Amount'] as String?;
    final fiatEquiv = responseJSON['Fiat_Equiv'] as String?;
    final amountTo = responseJSON['AmountTo'] as double;
    final coinTo = responseJSON['CoinTo'] as String;
    final address = responseJSON['Address'] as String;

    return AnonpayStatusResponse(
      status: status,
      fiatAmount: fiatAmount,
      amountTo: amountTo,
      coinTo: coinTo,
      address: address,
      fiatEquiv: fiatEquiv,
    );
  }

  Future<AnonpayInvoiceInfo> createInvoice(AnonPayRequest request) async {
    final description = Uri.encodeComponent(request.description);
    final body = <String, dynamic>{
      'ticker_to': request.cryptoCurrency.title.toLowerCase(),
      'network_to': _networkFor(request.cryptoCurrency),
      'address': request.address,
      'name': request.name,
      'description': description,
      'email': request.email,
      'ref': anonpayRef,
      'markup': markup,
      'direct': 'False',
    };

    if (request.amount != null) {
      body['amount'] = request.amount;
    }
    if (request.fiatEquivalent != null) {
      body['fiat_equiv'] = request.fiatEquivalent;
    }
    final authority = await _getAuthority();

    final response = await get(Uri.https(authority, anonPayPath, body));

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final id = responseJSON['ID'] as String;
    final url = responseJSON['url'] as String;
    final urlOnion = responseJSON['url_onion'] as String;
    final statusUrl = responseJSON['status_url'] as String;
    final statusUrlOnion = responseJSON['status_url_onion'] as String;

    final statusInfo = await paymentStatus(id);

    return AnonpayInvoiceInfo(
      invoiceId: id,
      clearnetUrl: url,
      onionUrl: urlOnion,
      status: statusInfo.status,
      fiatAmount: statusInfo.fiatAmount,
      fiatEquiv: statusInfo.fiatEquiv,
      amountTo: statusInfo.amountTo,
      coinTo: statusInfo.coinTo,
      address: statusInfo.address,
      clearnetStatusUrl: statusUrl,
      onionStatusUrl: statusUrlOnion,
      walletId: wallet.id,
      createdAt: DateTime.now(),
      provider: AnonpayProviderDescription.anonpayInvoice,
    );
  }

  Future<AnonpayInvoiceInfo> generateDonationLink(AnonPayRequest request) async {
    final description = Uri.encodeComponent(request.description);
    final body = <String, dynamic>{
      'ticker_to': request.cryptoCurrency.title.toLowerCase(),
      'network_to': _networkFor(request.cryptoCurrency),
      'address': request.address,
      'name': request.name,
      'description': description,
      'email': request.email,
      'ref': anonpayRef,
      'direct': 'True',
    };

    final clearnetUrl = Uri.https(clearNetAuthority, anonPayPath, body);
    final onionUrl = Uri.https(onionApiAuthority, anonPayPath, body);
    return AnonpayInvoiceInfo(
        clearnetUrl: clearnetUrl.toString(),
        onionUrl: onionUrl.toString(),
        provider: AnonpayProviderDescription.anonpayDonationLink);
  }

  Future<Limits> fetchLimits({
    required CryptoCurrency currency,
  }) async {
    final params = <String, String>{
      'api_key': apiKey,
      'ticker': currency.title.toLowerCase(),
      'name': currency.name,
    };

    final String apiAuthority = await _getAuthority();
    final uri = Uri.https(apiAuthority, coinPath, params);

    final response = await get(uri);

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as List<dynamic>;

    if (responseJSON.isEmpty) {
      throw Exception('No data');
    }

    final coinJson = responseJSON.first as Map<String, dynamic>;

    return Limits(
      min: coinJson['minimum'] as double,
      max: coinJson['maximum'] as double,
    );
  }

  Future<Limits> getLimits(CryptoCurrency currency) async {
    final authority = await _getAuthority();
    final response = await get(Uri.https(authority, '/anonpay/limits'));
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final limits = responseJSON['limits'] as Map<String, dynamic>;
    final currencyLimits = limits[currency.title.toLowerCase()] as Map<String, dynamic>;
    final min = currencyLimits['min'] as double;
    final max = currencyLimits['max'] as double;
    return Limits(min: min, max: max);
  }

  String _networkFor(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.usdt:
        return CryptoCurrency.btc.title.toLowerCase();
      default:
        return currency.tag != null ? _normalizeTag(currency.tag!) : 'Mainnet';
    }
  }

  String _normalizeTag(String tag) {
    switch (tag) {
      case 'ETH':
        return 'ERC20';
      default:
        return tag.toLowerCase();
    }
  }

  Future<String> _getAuthority() async {
    try {
      if (useTorOnly) {
        return onionApiAuthority;
      }
      final uri = Uri.https(onionApiAuthority, '/anonpay');
      await get(uri);
      return onionApiAuthority;
    } catch (e) {
      return clearNetAuthority;
    }
  }
}
