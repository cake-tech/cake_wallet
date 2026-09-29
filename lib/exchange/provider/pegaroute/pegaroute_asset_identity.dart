import 'dart:convert';

import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_currency_mapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/tron_token.dart';

/// Lossless canonical token identity for a Pegaroute Trade asset. Display
/// metadata alone must never be used to recover a missing contract or mint.
final class PegarouteAssetIdentity {
  const PegarouteAssetIdentity._();

  static const _mapper = PegarouteCurrencyMapper();

  /// Wallet metadata must agree with known canonical assets. Unknown metadata
  /// never inherits precision from a matching ticker or an API observation.
  static void validateMetadata(CryptoCurrency currency) {
    final asset = _mapper.map(currency);
    if (currency.decimals < 0 || currency.decimals > 36) {
      throw const FormatException('Invalid asset precision');
    }
    for (final known in CryptoCurrency.all) {
      PegarouteAssetId mapped;
      try { mapped = _mapper.map(known); }
      on PegarouteCurrencyException { continue; }
      if (mapped.chain == asset.chain && mapped.token == asset.token && known.decimals != currency.decimals) {
        throw const FormatException('Canonical asset precision changed');
      }
    }
  }

  static String? encode(CryptoCurrency? currency) {
    final String kind;
    final int? chainId;
    final String? mint;
    if (currency is Erc20Token) {
      kind = 'erc20';
      chainId = currency.chainId;
      mint = null;
    } else if (currency is SPLToken) {
      kind = 'spl';
      chainId = null;
      mint = currency.mint;
    } else if (currency is TronToken) {
      kind = 'tron';
      chainId = null;
      mint = null;
    } else {
      return null;
    }
    final asset = _mapper.map(currency!);
    return jsonEncode({
      'version': 1,
      'kind': kind,
      'chain': asset.chain,
      'token': asset.token,
      'nativeToken': asset.nativeToken,
      'decimals': currency.decimals,
      'chainId': chainId,
      'name': currency.name,
      'symbol': currency.symbol,
      'tag': currency.tag,
      'mint': mint,
      'iconPath': currency.iconPath,
    });
  }

  static CryptoCurrency decode(String raw) {
    final value = jsonDecode(raw);
    const keys = {
      'version',
      'kind',
      'chain',
      'token',
      'nativeToken',
      'decimals',
      'chainId',
      'name',
      'symbol',
      'tag',
      'mint',
      'iconPath',
    };
    if (value is! Map<String, dynamic> ||
        value.length != keys.length ||
        value.keys.any((key) => !keys.contains(key)) ||
        value['version'] is! int ||
        value['version'] != 1 ||
        value['decimals'] is! int ||
        (value['decimals'] as int) < 0 ||
        (value['decimals'] as int) > 255 ||
        value['chainId'] != null && value['chainId'] is! int) {
      throw const FormatException('invalid Pegaroute asset identity');
    }
    String string(String key, {bool allowEmpty = false}) {
      final field = value[key];
      if (field is! String || !allowEmpty && field.isEmpty) {
        throw const FormatException('missing Pegaroute asset identity field');
      }
      return field;
    }

    String? optionalString(String key) {
      final field = value[key];
      if (field != null && field is! String) {
        throw const FormatException('invalid Pegaroute asset metadata');
      }
      return field as String?;
    }

    final chain = string('chain');
    final token = string('token');
    final nativeToken = string('nativeToken');
    final asset = _mapper.validateCanonicalTuple(
      chain: chain,
      token: token,
      nativeToken: nativeToken,
    );
    final separator = token.indexOf('-');
    final symbol = string('symbol');
    if (asset.chain != chain ||
        separator <= 0 ||
        token.substring(0, separator) != symbol.toUpperCase()) {
      throw const FormatException('non-canonical Pegaroute token identity');
    }
    final address = token.substring(separator + 1);
    final name = string('name', allowEmpty: true);
    final decimals = value['decimals'] as int;
    final chainId = value['chainId'] as int?;
    final tag = optionalString('tag');
    final mint = optionalString('mint');
    final iconPath = optionalString('iconPath');
    final CryptoCurrency currency;
    switch (string('kind')) {
      case 'erc20':
        if (mint != null) {
          throw const FormatException('EVM token has a mint');
        }
        currency = Erc20Token(
          name: name,
          symbol: symbol,
          contractAddress: address,
          decimal: decimals,
          chainId: chainId,
          tag: tag,
          iconPath: iconPath,
        );
        break;
      case 'spl':
        if (chainId != null || mint == null) {
          throw const FormatException('invalid SPL token identity');
        }
        currency = SPLToken(
          name: name,
          symbol: symbol,
          mintAddress: address,
          decimal: decimals,
          mint: mint,
          tag: tag,
          iconPath: iconPath,
        );
        break;
      case 'tron':
        if (chainId != null || mint != null) {
          throw const FormatException('invalid TRON token identity');
        }
        currency = TronToken(
          name: name,
          symbol: symbol,
          contractAddress: address,
          decimal: decimals,
          tag: tag,
          iconPath: iconPath,
        );
        break;
      default:
        throw const FormatException('unsupported Pegaroute token kind');
    }
    if (!_mapper.matchesCanonicalTuple(currency, asset)) {
      throw const FormatException('Pegaroute token chain or contract changed');
    }
    return currency;
  }
}
