import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class RobinhoodBuyProvider extends BuyProvider {
  RobinhoodBuyProvider({required WalletBase wallet, bool isTestEnvironment = false, LedgerViewModel? ledgerVM})
      : super(wallet: wallet, isTestEnvironment: isTestEnvironment, ledgerVM: ledgerVM);

  static const _baseUrl = 'applink.robinhood.com';
  static const _cIdBaseUrl = 'exchange-helper.cakewallet.com';

  @override
  String get title => 'Robinhood Connect';

  @override
  String get providerDescription => S.current.robinhood_option_description;

  @override
  String get lightIcon => 'assets/images/robinhood_light.png';

  @override
  String get darkIcon => 'assets/images/robinhood_dark.png';

  String get _applicationId => secrets.robinhoodApplicationId;

  String get _apiSecret => secrets.exchangeHelperApiKey;

  Future<String> getSignature(String message) {
    switch (wallet.type) {
      case WalletType.ethereum:
      case WalletType.polygon:
        return wallet.signMessage(message);
      case WalletType.litecoin:
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
        return wallet.signMessage(message, address: wallet.walletAddresses.address);
      default:
        throw Exception("WalletType is not available for Robinhood ${wallet.type}");
    }
  }

  Future<String> getConnectId() async {
    final walletAddress = wallet.walletAddresses.address;
    final valid_until = (DateTime.now().millisecondsSinceEpoch / 1000).round() + 10;
    final message = "$_apiSecret:${valid_until}";

    final signature = await getSignature(message);

    final uri = Uri.https(_cIdBaseUrl, "/api/robinhood");

    var response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: json
            .encode({'valid_until': valid_until, 'wallet': walletAddress, 'signature': signature}));

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['connectId'] as String;
    } else {
      throw Exception(
          'Provider currently unavailable. Status: ${response.statusCode} ${response.body}');
    }
  }

  Future<Uri> requestProviderUrl() async {
    final connectId = await getConnectId();
    final networkName = wallet.currency.fullName?.toUpperCase().replaceAll(" ", "_");

    return Uri.https(_baseUrl, '/u/connect', <String, dynamic>{
      'applicationId': _applicationId,
      'connectId': connectId,
      'walletAddress': wallet.walletAddresses.address,
      'userIdentifier': wallet.walletAddresses.address,
      'supportedNetworks': networkName
    });
  }

  Future<void> launchProvider(BuildContext context, bool? isBuyAction) async {
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
      final uri = await requestProviderUrl();
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
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
