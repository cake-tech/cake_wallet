import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';

class WalletRestoreFromQRCode {
  WalletRestoreFromQRCode();

  static Future<RestoredWallet> scanQRCodeForRestoring(BuildContext context) async {
    final code = await presentQRScanner();
    Map<String, dynamic> credentials = {};
    Map<String, String> parameters = {};

    if (code.isEmpty) {
      throw Exception('Unexpected scan QR code value: value is empty');
    }
    final formattedUrl = getFormattedUrl(code);
    final uri = Uri.parse(formattedUrl);
    credentials['type'] = getWalletTypeFromUrl(uri.scheme);
    credentials['address'] = getAddressFromUrl(
      type: credentials['type'] as WalletType,
      address: uri.path,
    );
    parameters = uri.queryParameters;
    credentials['mode'] = getWalletRestoreMode(parameters);
    credentials.addAll(parameters);

    switch (credentials['mode']) {
      case WalletRestoreMode.txids:
        return RestoredWallet.fromTxIds(credentials);
      case WalletRestoreMode.seed:
        return RestoredWallet.fromSeed(credentials);
      case WalletRestoreMode.keys:
        return RestoredWallet.fromKey(credentials);
      default:
        throw Exception('Unexpected restore mode: ${credentials['mode']}');
    }
  }

  static String getFormattedUrl(String url) {
    int idx = url.indexOf(":");
    String substring1 = url.substring(0, idx);
    String substring2 = url.substring(idx);
    final result =
        substring1.contains('_') ? substring1.substring(0, substring1.indexOf('_')) : substring1;
    return result + substring2;
  }

  static WalletType getWalletTypeFromUrl(String scheme) {
    switch (scheme) {
      case 'monero':
        return WalletType.monero;
      case 'bitcoin':
        return WalletType.bitcoin;
      case 'litecoin':
        return WalletType.litecoin;
      default:
        throw Exception('Unexpected wallet type: ${scheme.toString()}');
    }
  }

  static String getAddressFromUrl({required WalletType type, required String address}) {
    final formattedAddress = address.replaceAll('address=', '').toString();
    final addressPattern = AddressValidator.getPattern(walletTypeToCryptoCurrency(type));
    final match = RegExp(addressPattern).hasMatch(formattedAddress);
    return match
        ? formattedAddress
        : throw Exception('Unexpected wallet address: address is invalid'
            'or does not match the type ${type.toString()}');
  }

  static WalletRestoreMode getWalletRestoreMode(Map<String, String> parameters) {
    if (parameters.containsKey('tx_payment_id')) {
      final txIdValue = parameters['tx_payment_id'] ?? '';
      return txIdValue.isNotEmpty
          ? WalletRestoreMode.txids
          : throw Exception('Unexpected restore mode: tx_payment_id is invalid');
    }

    if (parameters.containsKey('mnemonic_seed')) {
      //TODO implement seed validation
      final seedValue = parameters['mnemonic_seed'] ?? '';
      return seedValue.isNotEmpty
          ? WalletRestoreMode.seed
          : throw Exception('Unexpected restore mode: mnemonic_seed is invalid');
    }

    if (parameters.containsKey('seed')) {
      final seedValue = parameters['seed'] ?? '';
      return seedValue.isNotEmpty
          ? WalletRestoreMode.seed
          : throw Exception('Unexpected restore mode: seed is invalid');
    }

    if (parameters.containsKey('spend_key') && parameters.containsKey('view_key')) {
      final spendKeyValue = parameters['spend_key'] ?? '';
      final viewKeyValue = parameters['view_key'] ?? '';
      return spendKeyValue.isNotEmpty && viewKeyValue.isNotEmpty
          ? WalletRestoreMode.keys
          : throw Exception('Unexpected restore mode: spend_key or view_key is invalid');
    }

    throw Exception('Unexpected restore mode: restore params are invalid');
  }
}
