import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_ethereum/ethereum_wallet.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  String getElectrumSignature(String message, String walletAddress) {
    final wallet = _wallet as ElectrumWallet;
    final addressIndex = wallet.walletAddresses.addresses.firstWhere((element) => element.address == walletAddress).index;
    return wallet.signMessage(message, index: addressIndex);
  }

  String getEthereumSignature(String message) {
    final wallet = _wallet as EthereumWallet;
    return wallet.signMessage(message);
  }

  String getSignature(String message) {
    switch (_wallet.type) {
      case WalletType.ethereum:
        return getEthereumSignature(message);
      case WalletType.litecoin:
      case WalletType.bitcoin:
        return getElectrumSignature(message, _wallet.walletAddresses.address);
      default:
        throw Exception("WalletType is not available for Robinhood");
    }
  }

  Future<String> getConnectId() async {
    final walletAddress = _wallet.walletAddresses.address;
    final valid_until = (DateTime.now().millisecondsSinceEpoch / 1000).round() + 2000;
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
      throw Exception('Request failed with status: ${response.statusCode}. ${response.body}');
    }
  }

  Future<Uri> requestUrl(BuildContext context) async {
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
}
