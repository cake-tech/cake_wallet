import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/seed_validator.dart';
import 'package:cake_wallet/entities/mnemonic_item.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';

class WalletRestoreFromQRCode {
  WalletRestoreFromQRCode();

  static Future<RestoredWallet> scanQRCodeForRestoring(BuildContext context) async {
    String code = await presentQRScanner();
    Map<String, dynamic> credentials = {};

    if (code.isEmpty) {
      throw Exception('Unexpected scan QR code value: value is empty');
    }
    final formattedUri = getFormattedUri(code);
    final uri = Uri.parse(formattedUri);
    final queryParameters = uri.queryParameters;
    credentials['type'] = getWalletTypeFromUrl(uri.scheme);

    final address = getAddressFromUrl(
      type: credentials['type'] as WalletType,
      rawString: queryParameters.toString(),
    );
    if (address != null) {
      credentials['address'] = address;
    }

    final seed =
        getSeedPhraseFromUrl(queryParameters.toString(), credentials['type'] as WalletType);
    if (seed != null) {
      credentials['seed'] = seed;
    }
    credentials.addAll(queryParameters);
    credentials['mode'] = getWalletRestoreMode(credentials);

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

  static String getFormattedUri(String code) {
    final index = code.indexOf(':');
    final scheme = code.substring(0, index).replaceAll('_', '-');
    final query = code.substring(index + 1).replaceAll('?', '&');
    final formattedUri = '$scheme:?$query';
    return formattedUri;
  }

  static WalletType getWalletTypeFromUrl(String scheme) {
    switch (scheme) {
      case 'monero':
      case 'monero-wallet':
        return WalletType.monero;
      case 'bitcoin':
      case 'bitcoin-wallet':
        return WalletType.bitcoin;
      case 'litecoin':
      case 'litecoin-wallet':
        return WalletType.litecoin;
      default:
        throw Exception('Unexpected wallet type: ${scheme.toString()}');
    }
  }

  static String? getAddressFromUrl({required WalletType type, required String rawString}) {
    return AddressResolver.extractAddressByType(
        raw: rawString, type: walletTypeToCryptoCurrency(type));
  }

  static String? getSeedPhraseFromUrl(String rawString, WalletType walletType) {
    switch (walletType) {
      case WalletType.monero:
        RegExp regex25 = RegExp(r'\b(\S+\b\s+){24}\S+\b');
        RegExp regex14 = RegExp(r'\b(\S+\b\s+){13}\S+\b');
        RegExp regex13 = RegExp(r'\b(\S+\b\s+){12}\S+\b');

        if (regex25.firstMatch(rawString) == null) {
          if (regex14.firstMatch(rawString) == null) {
            if (regex13.firstMatch(rawString) == null) {
              return null;
            } else {
              return regex13.firstMatch(rawString)!.group(0)!;
            }
          } else {
            return regex14.firstMatch(rawString)!.group(0)!;
          }
        } else {
          return regex25.firstMatch(rawString)!.group(0)!;
        }
      case WalletType.bitcoin:
      case WalletType.litecoin:
        RegExp regex24 = RegExp(r'\b(\S+\b\s+){23}\S+\b');
        RegExp regex18 = RegExp(r'\b(\S+\b\s+){17}\S+\b');
        RegExp regex12 = RegExp(r'\b(\S+\b\s+){11}\S+\b');

        if (regex24.firstMatch(rawString) == null) {
          if (regex18.firstMatch(rawString) == null) {
            if (regex12.firstMatch(rawString) == null) {
              return null;
            } else {
              return regex12.firstMatch(rawString)!.group(0)!;
            }
          } else {
            return regex18.firstMatch(rawString)!.group(0)!;
          }
        } else {
          return regex24.firstMatch(rawString)!.group(0)!;
        }
      default:
        return null;
    }
  }

  static WalletRestoreMode getWalletRestoreMode(Map<String, dynamic> credentials) {
    final type = credentials['type'] as WalletType;
    if (credentials.containsKey('tx_payment_id')) {
      final txIdValue = credentials['tx_payment_id'] as String? ?? '';
      return txIdValue.isNotEmpty
          ? WalletRestoreMode.txids
          : throw Exception('Unexpected restore mode: tx_payment_id is invalid');
    }

    if (credentials.containsKey('seed')) {
      final seedValue = credentials['seed'] as String;
      final words = SeedValidator.getWordList(type: type, language: 'english');
      seedValue.split(' ').forEach((element) {
        if (!words.contains(element)) {
          throw Exception('Unexpected restore mode: mnemonic_seed is invalid');
        }
      });
      return WalletRestoreMode.seed;
    }

    if (credentials.containsKey('spend_key') || credentials.containsKey('view_key')) {
      final spendKeyValue = credentials['spend_key'] as String? ?? '';
      final viewKeyValue = credentials['view_key'] as String? ?? '';

      return spendKeyValue.isNotEmpty || viewKeyValue.isNotEmpty
          ? WalletRestoreMode.keys
          : throw Exception('Unexpected restore mode: spend_key or view_key is invalid');
    }

    throw Exception('Unexpected restore mode: restore params are invalid');
  }
}
