import 'dart:convert';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';

class DFXBuyProvider extends BuyProvider {
  DFXBuyProvider(
      {required WalletBase wallet, bool isTestEnvironment = false, LedgerViewModel? ledgerVM})
      : super(wallet: wallet, isTestEnvironment: isTestEnvironment, ledgerVM: ledgerVM);

  static const _baseUrl = 'api.dfx.swiss';

  // static const _signMessagePath = '/v1/auth/signMessage';
  static const _authPath = '/v1/auth';
  static const walletName = 'CakeWallet';

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

  String get assetOut {
    switch (wallet.type) {
      case WalletType.bitcoin:
        return 'BTC';
      case WalletType.bitcoinCash:
        return 'BCH';
      case WalletType.litecoin:
        return 'LTC';
      case WalletType.monero:
        return 'XMR';
      case WalletType.ethereum:
        return 'ETH';
      case WalletType.polygon:
        return 'MATIC';
      default:
        throw Exception("WalletType is not available for DFX ${wallet.type}");
    }
  }

  String get blockchain {
    switch (wallet.type) {
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
      case WalletType.litecoin:
        return 'Bitcoin';
      case WalletType.monero:
        return 'Monero';
      case WalletType.ethereum:
        return 'Ethereum';
      case WalletType.polygon:
        return 'Polygon';
      default:
        throw Exception("WalletType is not available for DFX ${wallet.type}");
    }
  }

  String get walletAddress =>
      wallet.walletAddresses.primaryAddress ?? wallet.walletAddresses.address;

  Future<String> getSignMessage() async =>
      "By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_Blockchain_address._Your_ID:_$walletAddress";

  // // Lets keep this just in case, but we can avoid this API Call
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

  Future<String> auth() async {
    final signMessage = await getSignature(await getSignMessage());

    final requestBody = jsonEncode({
      'wallet': walletName,
      'address': walletAddress,
      'signature': signMessage,
    });

    final uri = Uri.https(_baseUrl, _authPath);
    var response = await http.post(
      uri,
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
      throw Exception('Failed to sign up. Status: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> getSignature(String message) async {
    switch (wallet.type) {
      case WalletType.ethereum:
      case WalletType.polygon:
        return await wallet.signMessage(message);
      case WalletType.monero:
      case WalletType.litecoin:
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
        return await wallet.signMessage(message, address: walletAddress);
      default:
        throw Exception("WalletType is not available for DFX ${wallet.type}");
    }
  }

  // @override
  // Future<void> launchProvider(BuildContext context, bool? isBuyAction) async {
  //   if (wallet.isHardwareWallet) {
  //     if (!ledgerVM!.isConnected) {
  //       await Navigator.of(context).pushNamed(Routes.connectDevices,
  //           arguments: ConnectDevicePageParams(
  //               walletType: wallet.walletInfo.type,
  //               onConnectDevice: (BuildContext context, LedgerViewModel ledgerVM) {
  //                 ledgerVM.setLedger(wallet);
  //                 Navigator.of(context).pop();
  //               }));
  //     } else {
  //       ledgerVM!.setLedger(wallet);
  //     }
  //   }
  //
  //   try {
  //     final assetOut = this.assetOut;
  //     final blockchain = this.blockchain;
  //     final actionType = isBuyAction == true ? '/buy' : '/sell';
  //
  //     final accessToken = await auth();
  //
  //     final uri = Uri.https('services.dfx.swiss', actionType, {
  //       'session': accessToken,
  //       'lang': 'en',
  //       'asset-out': assetOut,
  //       'blockchain': blockchain,
  //       'asset-in': 'EUR',
  //     });
  //
  //     if (await canLaunchUrl(uri)) {
  //       if (DeviceInfo.instance.isMobile) {
  //         Navigator.of(context).pushNamed(Routes.webViewPage, arguments: [title, uri]);
  //       } else {
  //         await launchUrl(uri, mode: LaunchMode.externalApplication);
  //       }
  //     } else {
  //       throw Exception('Could not launch URL');
  //     }
  //   } catch (e) {
  //     await showPopUp<void>(
  //         context: context,
  //         builder: (BuildContext context) {
  //           return AlertWithOneAction(
  //               alertTitle: "DFX.swiss",
  //               alertContent: S.of(context).buy_provider_unavailable + ': $e',
  //               buttonText: S.of(context).ok,
  //               buttonAction: () => Navigator.of(context).pop());
  //         });
  //   }
  // }

  Future<Map<String, dynamic>> fetchFiatCredentials(String fiatCurrency) async {
    final url = Uri.https(_baseUrl, '/v1/fiat');

    try {
      final response = await http.get(url, headers: {'accept': 'application/json'});

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
      print('DFX Error fetching fiat currencies: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchAssetCredential(String assetsName) async {
    final blockchain = CryptoCurrency.fromString(assetsName);

    final url = Uri.https(_baseUrl, '/v1/asset', {'blockchains': blockchain.fullName});

    try {
      final response = await http.get(url, headers: {'accept': 'application/json'});

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List && responseData.isNotEmpty) {
          return responseData.first as Map<String, dynamic>;
        } else if (responseData is Map<String, dynamic>) {
          return responseData;
        } else {
          log('DFX: Does not support this asset name : ${blockchain.fullName}');
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
      String fiatCurrency, String cryptoCurrency, bool isBuyAction) async {
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
                final paymentMethod =
                    PaymentMethod.fromDFX(paymentMethodKey, getPaymentType(paymentMethodKey));
                paymentMethods.add(paymentMethod);
              }
            });
          }
        });
      }
    } else {
      final assetCredentials = await fetchAssetCredential(cryptoCurrency);
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
  Future<List<Quote>?> fetchQuote({
    required String sourceCurrency,
    required String destinationCurrency,
    required double amount,
    required bool isBuyAction,
    required String walletAddress,
    PaymentType? paymentType,
    String? countryCode}) async {

    String? paymentMethod;
    if (paymentType != null) {
      paymentMethod = normalizePaymentMethod(paymentType);
      if (paymentMethod == null) paymentMethod = paymentType.name;
    }


    final action = isBuyAction ? 'buy' : 'sell';

    final fiatCredentials =
        await fetchFiatCredentials(isBuyAction ? sourceCurrency : destinationCurrency);
    if (fiatCredentials['id'] == null) return null;

    final assetCredentials =
        await fetchAssetCredential(isBuyAction ? destinationCurrency : sourceCurrency);
    if (assetCredentials['id'] == null) return null;

    log(
        'DFX: Fetching $action quote: $sourceCurrency -> $destinationCurrency, amount: $amount');

    final url = Uri.parse('https://$_baseUrl/v1/$action/quote');
    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'currency': {
        'id': fiatCredentials['id'] as int,
      },
      'asset': {
        'id': assetCredentials['id'],
      },
      'amount': amount,
      'targetAmount': 0,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'discountCode': '',
    });

    try {
      final response = await http.put(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData is Map<String, dynamic>) {
          final quote = Quote.fromDFXJson(responseData, ProviderType.dfx, isBuyAction);
          quote.setSourceCurrency = sourceCurrency;
          quote.setDestinationCurrency = destinationCurrency;
          return [quote];
        } else {
          print('DFX: Unexpected data type: ${responseData.runtimeType}');
          return null;
        }
      } else {
        if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
          print('DFX Error: ${responseData['message']}');
        } else {
          print('DFX Failed to fetch buy quote: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      print('DFX Error fetching buy quote: $e');
      return null;
    }
  }

  Future<void>? launchProvider(
      {required BuildContext context,
        required Quote quote,
        required PaymentMethod paymentMethod,
        required double amount,
        required bool isBuyAction,
        required String cryptoCurrencyAddress,
        String? countryCode})  async {
    if (wallet.isHardwareWallet) {
      if (!ledgerVM!.isConnected) {
        await Navigator.of(context).pushNamed(Routes.connectDevices,
            arguments: ConnectDevicePageParams(
                walletType: wallet.walletInfo.type,
                onConnectDevice: (BuildContext context, LedgerViewModel ledgerVM) {
                  ledgerVM.setLedger(wallet);
                  Navigator.of(context).pop();
                }));
      } else {
        ledgerVM!.setLedger(wallet);
      }
    }

    try {
      final actionType = isBuyAction ? '/buy' : '/sell';
      final blockchain =
          CryptoCurrency.fromString(isBuyAction ? quote.destinationCurrency : quote.sourceCurrency)
              .fullName;

      final accessToken = await auth();

      final uri = Uri.https('services.dfx.swiss', actionType, {
        'session': accessToken,
        'lang': 'en',
        'asset-out': quote.destinationCurrency,
        'blockchain': blockchain,
        'asset-in': quote.sourceCurrency,
      });

      if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: "DFX.swiss",
                alertContent: S.of(context).buy_provider_unavailable + ': $e',
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
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

  PaymentType getPaymentType(String? paymentMethod) {
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
}
