import 'dart:convert';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DFXBuyProvider {
  DFXBuyProvider({required WalletBase wallet}) : this._wallet = wallet;

  final WalletBase _wallet;

  static const _baseUrl = 'api.dfx.swiss';
  static const _authPath = '/v1/auth/signMessage';
  static const _signUpPath = '/v1/auth/signUp';
  static const _signInPath = '/v1/auth/signIn';
  static const walletName = 'CakeWallet';

  Future<String> getSignMessage() async {
    final walletAddress = _wallet.walletAddresses.address;
    final uri = Uri.https(_baseUrl, _authPath, {'address': walletAddress});

    var response = await http.get(uri, headers: {'accept': 'application/json'});

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['message'] as String;
    } else {
      throw Exception(
          'Failed to get sign message. Status: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> signUp() async {
    final signMessage = getSignature(await getSignMessage());
    final walletAddress = _wallet.walletAddresses.address;

    final requestBody = jsonEncode({
      'wallet': walletName,
      'address': walletAddress,
      'signature': signMessage,
    });

    final uri = Uri.https(_baseUrl, _signUpPath);
    var response = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: requestBody);

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      return responseBody['accessToken'] as String;
    } else {
      throw Exception(
          'Failed to sign up. Status: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> signIn() async {
    final signMessage = getSignature(await getSignMessage());
    final walletAddress = _wallet.walletAddresses.address;

    final requestBody = jsonEncode({
      'address': walletAddress,
      'signature': signMessage,
    });

    final uri = Uri.https(_baseUrl, _signInPath);
    var response = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: requestBody);

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      return responseBody['accessToken'] as String;
    } else {
      throw Exception(
          'Failed to sign in. Status: ${response.statusCode} ${response.body}');
    }
  }

  String getSignature(String message) {
    switch (_wallet.type) {
      case WalletType.ethereum:
        return _wallet.signMessage(message);
      case WalletType.ethereum:
        return _wallet.signMessage(message);
      case WalletType.litecoin:
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
        return _wallet.signMessage(message,
            address: _wallet.walletAddresses.address);
      default:
        throw Exception("WalletType is not available for DFX ${_wallet.type}");
    }
  }

  Future<void> launchProvider(BuildContext context) async {
    try {
      String accessToken;

      try {
        accessToken = await signUp();
      } on Exception catch (e) {
        if (e.toString().contains('409')) {
          accessToken = await signIn();
        } else {
          rethrow;
        }
      }

      final uriString =
          'https://services.dfx.swiss/buy?session=$accessToken';
      final uri = Uri.parse(uriString);

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
                alertTitle: "DFX Connect",
                alertContent: S.of(context).buy_provider_unavailable + ': $e',
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
    }
  }
}
