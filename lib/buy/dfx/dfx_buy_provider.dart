import 'dart:convert';
import 'dart:developer';

import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/pairs_utils.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DFXBuyProvider extends BuyProvider {
  DFXBuyProvider({
    required WalletBase wallet,
    bool isTestEnvironment = false,
    HardwareWalletViewModel? hardwareWalletVM,
  }) : super(
          wallet: wallet,
          isTestEnvironment: isTestEnvironment,
          hardwareWalletVM: hardwareWalletVM,
          supportedCryptoList: supportedCryptoToFiatPairs(
              notSupportedCrypto: _notSupportedCrypto, notSupportedFiat: _notSupportedFiat),
          supportedFiatList: supportedFiatToCryptoPairs(
              notSupportedFiat: _notSupportedFiat, notSupportedCrypto: _notSupportedCrypto),
        );

  static const _baseUrl = 'api.dfx.swiss';

  // static const _signMessagePath = '/v1/auth/signMessage';
  static const _authPath = '/v1/auth';
  static const walletName = 'CakeWallet';

  static const List<CryptoCurrency> _notSupportedCrypto = [];
  static const List<FiatCurrency> _notSupportedFiat = [];

  @override
  String get title => 'DFX.swiss';

  @override
  String get providerDescription => S.current.dfx_option_description;

  @override
  String get lightIcon => 'assets/images/dfx_light.png';

  @override
  String get darkIcon => 'assets/images/dfx_dark.png';

  @override
  bool get isAggregator => false;

  String get blockchain {
    switch (wallet.type) {
      case WalletType.bitcoin:
        return 'Bitcoin';
      case WalletType.zano:
        return 'Zano';
      default:
        return walletTypeToString(wallet.type);
    }
  }


  Future<String> getSignMessage(String walletAddress) async =>
      "By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_Blockchain_address._Your_ID:_$walletAddress";

  // Lets keep this just in case, but we can avoid this API Call
  // Future<String> getSignMessage() async {
  //  final uri = Uri.https(_baseUrl, _signMessagePath, {'address': walletAddress});
  //
  //  final response = await http.get(uri, headers: {'accept': 'application/json'});
  //
  //  if (response.statusCode == 200) {
  //    final responseBody = jsonDecode(response.body);
  //    return responseBody['message'] as String;
  //  } else {
  //    throw Exception(
  //      'Failed to get sign message. Status: ${response.statusCode} ${response.body}');
  //  }
  // }

  Future<String> auth(String walletAddress) async {
    final signMessage = await getSignature(await getSignMessage(walletAddress), walletAddress);

    final requestBody = jsonEncode({
      'wallet': walletName,
      'address': walletAddress,
      'signature': signMessage,
    });

    final uri = Uri.https(_baseUrl, _authPath);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      return responseBody['accessToken'] as String;
    } else if (response.statusCode == 403) {
      final responseBody = jsonDecode(response.body);
      final message = responseBody['message'] ?? 'Service unavailable in your country';
      throw Exception(message);
    } else {
      throw Exception('Failed to sign up. ${_getErrorMessage(response.statusCode, response.body)}');
    }
  }

  Future<String> getSignature(String message, String walletAddress) async {
    switch (wallet.type) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.solana:
      case WalletType.tron:
        return wallet.signMessage(message);
      case WalletType.monero:
      case WalletType.litecoin:
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
      case WalletType.zano:
        return wallet.signMessage(message, address: walletAddress);
      default:
        throw Exception("WalletType is not available for DFX ${wallet.type}");
    }
  }

  Future<Map<String, dynamic>> fetchFiatCredentials(String fiatCurrency) async {
    final url = Uri.https(_baseUrl, '/v1/fiat');

    try {
      final response = await ProxyWrapper().get(
        clearnetUri: url,
        headers: {'accept': 'application/json'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        for (final item in data) {
          if (item['name'] == fiatCurrency) return item as Map<String, dynamic>;
        }
        log('DFX does not support fiat: $fiatCurrency');
        return {};
      } else {
        log('DFX Failed to fetch fiat currencies: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      printV('DFX Error fetching fiat currencies: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchAssetCredential(String assetsName) async {
    final url = Uri.https(_baseUrl, '/v1/asset', {'blockchains': blockchain});

    try {
      final response = await ProxyWrapper().get(clearnetUri: url, headers: {'accept': 'application/json'});
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List && responseData.isNotEmpty) {
          for (final i in responseData) {
            if (assetsName.toLowerCase() == i["dexName"].toString().toLowerCase()) {
              return i as Map<String, dynamic>;
            }
          }
          return responseData.first as Map<String, dynamic>;
        } else if (responseData is Map<String, dynamic>) {
          return responseData;
        } else {
          log('DFX: Does not support this asset name : ${blockchain}');
        }
      } else {
        log('DFX: Failed to fetch assets: ${response.statusCode}');
      }
    } catch (e) {
      log('DFX: Error fetching assets: $e');
    }
    return {};
  }

  Future<List<PaymentMethod>> getAvailablePaymentTypes(
      String fiatCurrency, CryptoCurrency cryptoCurrency, bool isBuyAction) async {
    final List<PaymentMethod> paymentMethods = [];

    if (isBuyAction) {
      final fiatBuyCredentials = await fetchFiatCredentials(fiatCurrency);
      if (fiatBuyCredentials.isNotEmpty) {
        fiatBuyCredentials.forEach((key, value) {
          if (key == 'limits') {
            final limits = value as Map<String, dynamic>;
            limits.forEach((paymentMethodKey, paymentMethodValue) {
              final min = _toDouble(paymentMethodValue['minVolume']);
              final max = _toDouble(paymentMethodValue['maxVolume']);
              if (min != null && max != null && min > 0 && max > 0) {
                final paymentMethod = PaymentMethod.fromDFX(
                    paymentMethodKey, _getPaymentTypeByString(paymentMethodKey));
                paymentMethods.add(paymentMethod);
              }
            });
          }
        });
      }
    } else {
      final assetCredentials = await fetchAssetCredential(cryptoCurrency.title);
      if (assetCredentials.isNotEmpty) {
        if (assetCredentials['sellable'] == true) {
          final availablePaymentTypes = [
            PaymentType.bankTransfer,
            PaymentType.creditCard,
            PaymentType.sepa
          ];
          availablePaymentTypes.forEach((element) {
            final paymentMethod = PaymentMethod.fromDFX(normalizePaymentMethod(element)!, element);
            paymentMethods.add(paymentMethod);
          });
        }
      }
    }

    return paymentMethods;
  }

  @override
  Future<List<Quote>?> fetchQuote(
      {required CryptoCurrency cryptoCurrency,
      required FiatCurrency fiatCurrency,
      required double amount,
      required bool isBuyAction,
      required String walletAddress,
      PaymentType? paymentType,
      String? customPaymentMethodType,
      String? countryCode}) async {
    /// if buying with any currency other than eur or chf then DFX is not supported

    if (isBuyAction && (fiatCurrency != FiatCurrency.eur && fiatCurrency != FiatCurrency.chf)) {
      return null;
    }

    String? paymentMethod;
    if (paymentType != null && paymentType != PaymentType.all) {
      paymentMethod = normalizePaymentMethod(paymentType);
      if (paymentMethod == null) paymentMethod = paymentType.name;
    } else {
      paymentMethod = 'Bank';
    }

    final action = isBuyAction ? 'buy' : 'sell';

    final fiatCredentials = await fetchFiatCredentials(fiatCurrency.name.toString());
    if (fiatCredentials['id'] == null) return null;

    final assetCredentials = await fetchAssetCredential(cryptoCurrency.title.toString());
    if (assetCredentials['id'] == null) return null;

    log('DFX: Fetching $action quote: ${isBuyAction ? cryptoCurrency : fiatCurrency} -> ${isBuyAction ? fiatCurrency : cryptoCurrency}, amount: $amount, paymentMethod: $paymentMethod');

    final url = Uri.https(_baseUrl, '/v1/$action/quote');
    final headers = {'accept': 'application/json', 'Content-Type': 'application/json'};
    final body = jsonEncode({
      'currency': {'id': fiatCredentials['id'] as int},
      'asset': {'id': assetCredentials['id']},
      'amount': amount,
      'targetAmount': 0,
      'paymentMethod': paymentMethod,
      'discountCode': ''
    });

    try {
      final response = await ProxyWrapper().put(
        clearnetUri: url,
        headers: headers,
        body: body,
      );
      
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData is Map<String, dynamic>) {
          final paymentType = _getPaymentTypeByString(responseData['paymentMethod'] as String?);
          final quote = Quote.fromDFXJson(responseData, isBuyAction, paymentType);
          quote.setFiatCurrency = fiatCurrency;
          quote.setCryptoCurrency = cryptoCurrency;
          return [quote];
        } else {
          printV('DFX: Unexpected data type: ${responseData.runtimeType}');
          return null;
        }
      } else {
        if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
          printV('DFX Error: ${responseData['message']}');
        } else {
          printV('DFX Failed to fetch buy quote: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      printV('DFX Error fetching buy quote: $e');
      return null;
    }
  }

  Future<void>? launchProvider(
      {required BuildContext context,
      required Quote quote,
      required double amount,
      required bool isBuyAction,
      required String cryptoCurrencyAddress,
      String? countryCode}) async {
    if (wallet.isHardwareWallet) {
      if (!hardwareWalletVM!.isConnected) {
        await Navigator.of(context).pushNamed(Routes.connectDevices,
            arguments: ConnectDevicePageParams(
                walletType: wallet.walletInfo.type,
                hardwareWalletType: wallet.walletInfo.hardwareWalletType!,
                onConnectDevice: (context, hwwVM) {
                  hwwVM.initWallet(wallet);
                  Navigator.of(context).pop();
                }));
      } else {
        hardwareWalletVM!.initWallet(wallet);
      }
    }

    try {
      final actionType = isBuyAction ? '/buy' : '/sell';

      final accessToken = await auth(cryptoCurrencyAddress);

      final uri = Uri.https('app.dfx.swiss', actionType, {
        'session': accessToken,
        'lang': 'en',
        'asset-out': isBuyAction ? quote.cryptoCurrency.toString() : quote.fiatCurrency.toString(),
        'blockchain': blockchain,
        'asset-in': isBuyAction ? quote.fiatCurrency.toString() : quote.cryptoCurrency.toString(),
        'amount-in': amount.toString()
      });

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      await showPopUp<void>(
        context: context,
        builder: (context) => AlertWithOneAction(
            alertTitle: "DFX.swiss",
            alertContent: '${S.of(context).buy_provider_unavailable}: $e',
            buttonText: S.of(context).ok,
            buttonAction: () => Navigator.of(context).pop()),
      );
    }
  }

  String? normalizePaymentMethod(PaymentType paymentMethod) {
    switch (paymentMethod) {
      case PaymentType.bankTransfer:
        return 'Bank';
      case PaymentType.creditCard:
        return 'Card';
      case PaymentType.sepa:
        return 'Instant';
      default:
        return null;
    }
  }

  PaymentType _getPaymentTypeByString(String? paymentMethod) {
    switch (paymentMethod) {
      case 'Bank':
        return PaymentType.bankTransfer;
      case 'Card':
        return PaymentType.creditCard;
      case 'Instant':
        return PaymentType.sepa;
      default:
        return PaymentType.unknown;
    }
  }

  double? _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    }
    return null;
  }

  String _getErrorMessage(int statusCode, String body) {
    final responseBody = jsonDecode(body) as Map<String, dynamic>;
    final message = responseBody['message']?.toString() ?? '';

    if (message.contains("address must match")) {
      return "The wallet type must match the selected currency";
    }

    return message.isNotEmpty ? message : "Unknown error: ${statusCode}";
  }
}
