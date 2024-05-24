import 'dart:convert';

import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DFXBuyProvider extends BuyProvider {
  DFXBuyProvider({required WalletBase wallet, bool isTestEnvironment = false, LedgerViewModel? ledgerVM})
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
        return wallet.signMessage(message);
      case WalletType.monero:
      case WalletType.litecoin:
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
        return wallet.signMessage(message, address: walletAddress);
      default:
        throw Exception("WalletType is not available for DFX ${wallet.type}");
    }
  }

  @override
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
      final assetOut = this.assetOut;
      final blockchain = this.blockchain;
      final actionType = isBuyAction == true ? '/buy' : '/sell';

      final accessToken = await auth();

      final uri = Uri.https('services.dfx.swiss', actionType, {
        'session': accessToken,
        'lang': 'en',
        'asset-out': assetOut,
        'blockchain': blockchain,
        'asset-in': 'EUR',
      });

      if (await canLaunchUrl(uri)) {
        if (DeviceInfo.instance.isMobile) {
          Navigator.of(context).pushNamed(Routes.webViewPage, arguments: [title, uri]);
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
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
}
