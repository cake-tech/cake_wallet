import 'dart:convert';
import 'dart:isolate';

import 'package:basic_utils/basic_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:dnssec_proof/dnssec_proof.dart';

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

}
