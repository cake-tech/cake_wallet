import 'package:cake_wallet/core/seed_validator.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';

class WalletRestoreFromQRCode {
  WalletRestoreFromQRCode();

  static const Map<String, WalletType> _walletSchemeMap = {
    'monero': WalletType.monero,
    'monero-wallet': WalletType.monero,
    'monero_wallet': WalletType.monero,
    'bitcoin': WalletType.bitcoin,
    'bitcoin-wallet': WalletType.bitcoin,
    'bitcoin_wallet': WalletType.bitcoin,
    'litecoin': WalletType.litecoin,
    'litecoin-wallet': WalletType.litecoin,
    'litecoin_wallet': WalletType.litecoin,
    'ethereum-wallet': WalletType.ethereum,
  };

  static bool _containsAssetSpecifier(String code) =>
      code.contains(':') && _startWithValidWalletAsset(code);

  static bool _startWithValidWalletAsset(String code) {
    return _walletSchemeMap.keys.any((scheme) => code.startsWith(scheme));
  }

  static WalletType _getWalletTypeFromUrlScheme(String scheme) {
    final walletType = _walletSchemeMap[scheme];
    if (walletType != null) {
      return walletType;
    }
    throw Exception('Unexpected wallet type: $scheme');
  }

  static String? _extractAddressFromUrl(WalletType type, String rawString) {
    return AddressResolver.extractAddressByType(
        raw: rawString, type: walletTypeToCryptoCurrency(type));
  }

  static String? _extractSeedPhraseFromUrl(String rawString, WalletType walletType) {
    RegExp _getPattern(int wordCount) =>
        RegExp(r'\b(\S+\b\s+){' + (wordCount - 1).toString() + r'}\S+\b');
    String? _matchPattern(int wordCount) {
      final pattern = _getPattern(wordCount);
      final match = pattern.firstMatch(rawString);
      return match?.group(0);
    }

    List<int> patternCounts = walletType == WalletType.monero ? [25, 14, 13] : [24, 18, 12];

    for (final count in patternCounts) {
      final result = _matchPattern(count);
      if (result != null) return result;
    }

    return null;
  }

  static Future<RestoredWallet> scanQRCodeForRestoring(BuildContext context) async {
    String code = await presentQRScanner();
    if (code.isEmpty) throw Exception('Unexpected scan QR code value: value is empty');

    WalletType? walletType;
    String formattedUri = '';

    if (!_containsAssetSpecifier(code)) {
      await _specifyWalletAssets(context, "Can't determine wallet type, please pick it manually");
      walletType =
          await Navigator.pushNamed(context, Routes.restoreWalletTypeFromQR) as WalletType?;
      if (walletType == null) throw Exception("Failed to determine wallet type.");

      formattedUri = _extractSeedPhraseFromUrl(code, walletType) != null
          ? '$walletType:?$code'
          : throw Exception('Failed to determine valid seed phrase');
    } else {
      final index = code.indexOf(':');
      final scheme = code.substring(0, index).replaceAll('_', '-');
      final query = code.substring(index + 1).replaceAll('?', '&');
      formattedUri = '$scheme:?$query';
      walletType = _getWalletTypeFromUrlScheme(scheme);
    }

    final uri = Uri.parse(formattedUri);
    final queryParameters = uri.queryParameters;

    Map<String, dynamic> credentials = {'type': walletType, ...queryParameters};
    credentials['address'] = _extractAddressFromUrl(walletType!, queryParameters.toString());
    credentials['seed'] = _extractSeedPhraseFromUrl(queryParameters.toString(), walletType);
    if (credentials['seed'] == null) credentials['private_key'] = queryParameters['private_key'];

    credentials['mode'] = _determineWalletRestoreMode(credentials);

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

  static WalletRestoreMode _determineWalletRestoreMode(Map<String, dynamic> credentials) {
    final type = credentials['type'] as WalletType;
    if (credentials.containsKey('tx_payment_id')) {
      final txIdValue = credentials['tx_payment_id'] as String? ?? '';
      if (txIdValue.isNotEmpty) return WalletRestoreMode.txids;
      throw Exception('Unexpected restore mode: tx_payment_id is invalid');
    }

    if (credentials.containsKey('seed')) {
      final seedValue = credentials['seed'] as String;
      final words = SeedValidator.getWordList(type: type, language: 'english');
      seedValue.split(' ').forEach((element) {
        if (!words.contains(element)) {
          throw Exception('Unexpected restore mode: mnemonic_seed is invalid or does\'t match wallet type');
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

    if (type == WalletType.ethereum && credentials.containsKey('private_key')) {
      final privateKey = credentials['private_key'] as String;
      if (privateKey.isEmpty) {
        throw Exception('Unexpected restore mode: private_key');
      }
      return WalletRestoreMode.keys;
    }

    throw Exception('Unexpected restore mode: restore params are invalid');
  }
}

Future<void> _specifyWalletAssets(BuildContext context, String error) async {
  await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithOneAction(
            alertTitle: S.current.error,
            alertContent: error,
            buttonText: S.of(context).ok,
            buttonAction: () => Navigator.of(context).pop());
      });
}
