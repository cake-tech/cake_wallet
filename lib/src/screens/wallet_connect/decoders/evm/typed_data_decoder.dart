import 'dart:convert';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart';
import 'package:cw_core/utils/print_verbose.dart';

class TypedDataDecoder {
  WCDecodedRequest decode(dynamic raw) {
    final parsed = _parsePayload(raw);
    if (parsed == null) {
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_sign_typed_data,
        warnings: [S.current.wc_warning_typed_data_invalid],
        rawFallback: raw is String ? raw : raw?.toString(),
      );
    }
    final domain = (parsed['domain'] as Map?)?.cast<String, dynamic>() ?? const {};
    final primaryType = parsed['primaryType']?.toString() ?? '';
    final types = (parsed['types'] as Map?)?.cast<String, dynamic>() ?? const {};
    final message = (parsed['message'] as Map?)?.cast<String, dynamic>() ?? const {};

    final rows = <WCDecodedRow>[];

    final domainName = domain['name']?.toString();
    if (domainName != null && domainName.isNotEmpty) {
      rows.add(WCDecodedRow(label: S.current.wc_domain, value: domainName));
    }
    final version = domain['version']?.toString();
    if (version != null && version.isNotEmpty) {
      rows.add(WCDecodedRow(label: S.current.wc_domain_version, value: version));
    }
    final chainId = domain['chainId']?.toString();
    if (chainId != null && chainId.isNotEmpty) {
      rows.add(WCDecodedRow(label: S.current.chain_id, value: chainId));
    }
    final verifyingContract = domain['verifyingContract']?.toString();
    if (verifyingContract != null && verifyingContract.isNotEmpty) {
      rows.add(WCDecodedRow(
        label: S.current.wc_verifying_contract,
        value: verifyingContract,
        kind: WCDecodedRowKind.address,
      ));
    }
    if (primaryType.isNotEmpty) {
      rows.add(WCDecodedRow(label: S.current.wc_primary_type, value: primaryType));
    }

    final messageRows = _flattenMessage(message, types, primaryType, prefix: '');
    rows.addAll(messageRows);

    final isPermit = primaryType.toLowerCase().contains('permit');
    return WCDecodedRequest(
      actionTitle: isPermit ? S.current.wc_action_permit : S.current.wc_action_sign_typed_data,
      actionSubtitle: primaryType.isEmpty ? null : primaryType,
      rows: rows,
      warnings: isPermit ? [S.current.wc_warning_permit_review] : const [],
      hideTo: true,
      hideZeroValue: true,
      rawFallback: const JsonEncoder.withIndent('  ').convert(parsed),
    );
  }

  Map<String, dynamic>? _parsePayload(dynamic raw) {
    try {
      if (raw is Map) return raw.cast<String, dynamic>();
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      }
      if (raw is List && raw.length >= 2 && raw[1] is String) {
        final decoded = jsonDecode(raw[1] as String);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      }
    } catch (e) {
      printV('TypedDataDecoder: failed to parse payload: $e');
    }
    return null;
  }

  List<WCDecodedRow> _flattenMessage(
    Map<String, dynamic> message,
    Map<String, dynamic> types,
    String typeName, {
    required String prefix,
  }) {
    final out = <WCDecodedRow>[];
    final fields = (types[typeName] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    if (fields.isEmpty) {
      for (final entry in message.entries) {
        out.add(WCDecodedRow(
          label: prefix.isEmpty ? entry.key : '$prefix.${entry.key}',
          value: _stringifyValue(entry.value),
        ));
      }
      return out;
    }

    for (final field in fields) {
      final name = field['name']?.toString() ?? '';
      final fieldType = field['type']?.toString() ?? '';
      final value = message[name];
      if (value == null) continue;
      final label = prefix.isEmpty ? name : '$prefix.$name';

      if (types.containsKey(fieldType) && value is Map) {
        out.addAll(_flattenMessage(
          value.cast<String, dynamic>(),
          types,
          fieldType,
          prefix: label,
        ));
      } else if (fieldType.endsWith(']') && value is List) {
        out.add(WCDecodedRow(label: label, value: '[${value.length}]'));
        for (var i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is Map) {
            final innerType = fieldType.substring(0, fieldType.lastIndexOf('['));
            if (types.containsKey(innerType)) {
              out.addAll(_flattenMessage(
                item.cast<String, dynamic>(),
                types,
                innerType,
                prefix: '$label[$i]',
              ));
              continue;
            }
          }
          out.add(WCDecodedRow(label: '$label[$i]', value: _stringifyValue(item)));
        }
      } else {
        out.add(WCDecodedRow(
          label: label,
          value: _stringifyValue(value),
          kind: _looksLikeAddress(fieldType, value)
              ? WCDecodedRowKind.address
              : WCDecodedRowKind.text,
        ));
      }
    }
    return out;
  }

  bool _looksLikeAddress(String fieldType, dynamic value) {
    if (fieldType == 'address') return true;
    if (value is String && value.length == 42 && value.startsWith('0x')) return true;
    return false;
  }

  String _stringifyValue(dynamic value) {
    if (value == null) return '';
    if (value is Map || value is List) {
      try {
        return jsonEncode(value);
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }
}
