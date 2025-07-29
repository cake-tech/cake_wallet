import 'dart:convert';
import 'dart:isolate';

import 'package:basic_utils/basic_utils.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_picker_option.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:dnssec_proof/dnssec_proof.dart';
import 'package:flutter/material.dart';

class Bip353Record {
  Bip353Record({
    required this.uri,
    required this.domain,
  });

  final String uri;
  final String domain;

  static const Map<String, String> keyDisplayMap = {
    'lno': 'BOLT 12 Offer',
    'sp': 'Silent Payment',
    'address': 'On-Chain Address',
  };

  static Future<String?> fetchDnsProof(String bip353Name) async {
    if (bip353Name.startsWith('₿')) {
      bip353Name = bip353Name.substring(1);
    }
    final parts = bip353Name.split('@');
    if (parts.length != 2) return null;
    final userPart = parts[0];
    final domainPart = parts[1];
    final bip353Domain = '$userPart.user._bitcoin-payment.$domainPart.';
    final proof = await Isolate.run(() => DnsProver.getTxtProof(bip353Domain));
    return base64.encode(proof);
  }

  static Future<Map<String, String>?> fetchUriByCryptoCurrency(
      String bip353Name, String asset) async {
    try {
      // 1. Parse the user and domain from "user@domain"
      final parts = bip353Name.split('@');

      if (parts.length != 2) return null;

      String userPart = parts[0];
      if (userPart.startsWith('₿')) {
        userPart = userPart.substring(1);
      }
      final domainPart = parts[1];

      // 2. Construct the correct subdomain: "user._bitcoin-payment.domain"
      final bip353Domain = '$userPart.user._bitcoin-payment.$domainPart';

      // 3. Lookup the TXT record with DNSSEC
      final txtRecords = await DnsUtils.lookupRecord(
        bip353Domain,
        RRecordType.TXT,
        dnssec: true,
      );
      final proof = await fetchDnsProof(bip353Name);
      if (proof == null) {
        throw Exception('DNSSEC proof not found');
      }

      if (txtRecords == null) return null;

      final assetName = CryptoCurrency.fromString(asset).fullName;
      if (assetName == null) throw Exception('Invalid asset name');
      final formattedAssetName = assetName.toLowerCase().replaceAll(' ', '') + ':';

      for (final record in txtRecords) {
        final data = record.data.replaceAll('"', '');
        if (data.startsWith(formattedAssetName)) {
          return _parseAssetUri(data, formattedAssetName);
        }
      }
    } catch (e) {
      printV('BIP353Record.fetchBitcoinUri error: $e');
    }
    return null;
  }

  static Map<String, String>? _parseAssetUri(String fullUri, String prefix) {
    final afterPrefix = fullUri.substring(prefix.length);
    if (afterPrefix.isEmpty) return null;

    final questionIndex = afterPrefix.indexOf('?');
    if (questionIndex == -1) {
      return {'address': afterPrefix};
    } else {
      final addressPart = afterPrefix.substring(0, questionIndex);
      final queryPart = afterPrefix.substring(questionIndex + 1);
      final result = <String, String>{};

      if (addressPart.isNotEmpty) result['address'] = addressPart;
      final queryMap = Uri.splitQueryString(queryPart);
      result.addAll(queryMap);

      return result;
    }
  }

  static Future<String?> pickBip353AddressChoice(
    BuildContext context,
    String bip353Name,
    Map<String, String> addressMap,
  ) async {
    if (addressMap.length == 1) {
      return addressMap.values.first;
    }

    final chosenAddress = await _showAddressChoiceDialog(context, bip353Name, addressMap);

    return chosenAddress;
  }

  static Future<String?> _showAddressChoiceDialog(
    BuildContext context,
    String bip353Name,
    Map<String, String> addressMap,
  ) async {
    final entriesList = addressMap.entries.toList();
    final List<Map<String, String>> displayItems = entriesList.map((entry) {
      final originalKey = entry.key;
      final originalValue = entry.value;

      final extendedKeyName = keyDisplayMap[originalKey] ?? originalKey;
      final truncatedValue = _truncate(originalValue, front: 6, back: 6);

      return {
        'displayKey': extendedKeyName,
        'displayValue': truncatedValue,
        'originalKey': originalKey,
        'originalValue': originalValue,
      };
    }).toList();

    String? selectedOriginalValue;

    if (context.mounted) {
      await showPopUp<void>(
        context: context,
        builder: (dialogContext) {
          return AlertWithPickerOption(
            alertTitle:  S.of(context).multiple_addresses_detected + '\n$bip353Name',
            alertTitleTextSize: 14,
            alertSubtitle: S.of(context).please_choose_one + ':',
            options: displayItems,
            onOptionSelected: (Map<String, String> chosenItem) {
              selectedOriginalValue = chosenItem['originalValue'];
            },
            alertBarrierDismissible: true,
          );
        },
      );
    }
    return selectedOriginalValue;
  }

  static String _truncate(String value, {int front = 6, int back = 6}) {
    if (value.length <= front + back) return value;

    final start = value.substring(0, front);
    final end = value.substring(value.length - back);
    return '$start...$end';
  }

}
