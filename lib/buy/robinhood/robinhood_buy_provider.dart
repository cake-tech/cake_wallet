import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class RobinhoodBuyProvider {
  RobinhoodBuyProvider({required WalletBase wallet})
      : this._wallet = wallet;

  final WalletBase _wallet;

  static const _baseUrl = 'applink.robinhood.com';
  static const _cIdBaseUrl = 'exchange-helper.cakewallet.com';

  String get _applicationId => secrets.robinhoodApplicationId;
  String get _apiSecret => secrets.robinhoodCIdApiSecret;

  bool get isAvailable =>
      [WalletType.bitcoin, WalletType.litecoin, WalletType.ethereum].contains(_wallet.type);

  String getSignature(String message) {
    switch (_wallet.type) {
      case WalletType.ethereum:
        return _wallet.signMessage(message);
      case WalletType.litecoin:
      case WalletType.bitcoin:
        return _wallet.signMessage(message, address: _wallet.walletAddresses.address);
      default:
        throw Exception("WalletType is not available for Robinhood ${_wallet.type}");
    }
  }

  Future<String> getConnectId() async {
    final walletAddress = _wallet.walletAddresses.address;
    final valid_until = (DateTime.now().millisecondsSinceEpoch / 1000).round() + 10;
    final message = "$_apiSecret:${valid_until}";

    final signature = getSignature(message);

    final uri = Uri.https(_cIdBaseUrl, "/api/robinhood");

    var response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: json
            .encode({'valid_until': valid_until, 'wallet': walletAddress, 'signature': signature}));

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['connectId'] as String;
    } else {
      throw Exception('Provider currently unavailable. Status: ${response.statusCode} ${response.body}');
    }
  }

  Future<Uri> requestUrl() async {
    final connectId = await getConnectId();
    final networkName = _wallet.currency.fullName?.toUpperCase().replaceAll(" ", "_");

    return Uri.https(_baseUrl, '/u/connect', <String, dynamic>{
      'applicationId': _applicationId,
      'connectId': connectId,
      'walletAddress': _wallet.walletAddresses.address,
      'userIdentifier': _wallet.walletAddresses.address,
      'supportedNetworks': networkName
    });
  }

  Future<void> launchProvider(BuildContext context) async {
    try {
      final uri = await requestUrl();
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, s) {
      ExceptionHandler.onError(FlutterErrorDetails(exception: e, stack: s));
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: "Robinhood Connect",
                alertContent: S.of(context).buy_provider_unavailable,
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
    }
  }
}
