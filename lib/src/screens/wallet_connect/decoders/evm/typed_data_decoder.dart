import "dart:convert";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/utils/print_verbose.dart";

class TypedDataDecoder {
  TypedDataDecoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  static const _timestampFieldNames = {
    "deadline",
    "sigdeadline",
    "expiration",
    "expiry",
    "expiretime",
    "expirationtime",
    "validuntil",
    "validafter",
  };

  Future<WCDecodedRequest> decode(dynamic raw) async {
    final legacy = _decodeLegacyV1(raw);
    if (legacy != null) {
      return legacy;
    }

    final parsed = _parsePayload(raw);
    if (parsed == null) {
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_sign_typed_data,
        warnings: [S.current.wc_warning_typed_data_invalid],
        rawFallback: raw is String ? raw : raw?.toString(),
      );
    }

    final domain = (parsed["domain"] as Map?)?.cast<String, dynamic>() ?? const {};
    final primaryType = parsed["primaryType"]?.toString() ?? "";
    final types = (parsed["types"] as Map?)?.cast<String, dynamic>() ?? const {};
    final message = (parsed["message"] as Map?)?.cast<String, dynamic>() ?? const {};
    final rawFallback = const JsonEncoder.withIndent("  ").convert(parsed);

    final semantic = await _decodePermitSemantics(
      primaryType: primaryType,
      domain: domain,
      message: message,
      rawFallback: rawFallback,
    );
    if (semantic != null) {
      return semantic;
    }

    final rows = <WCDecodedRow>[];
    _addDomainRows(rows, domain, primaryType);
    rows.addAll(_flattenMessage(message, types, primaryType, prefix: ""));

    final isPermit = primaryType.toLowerCase().contains("permit");
    return WCDecodedRequest(
      actionTitle: isPermit ? S.current.wc_action_permit : S.current.wc_action_sign_typed_data,
      actionSubtitle: primaryType.isEmpty ? null : primaryType,
      rows: rows,
      warnings: isPermit ? [S.current.wc_warning_permit_review] : const [],
      hideTo: true,
      hideValue: true,
      rawFallback: rawFallback,
    );
  }

  void _addDomainRows(
    List<WCDecodedRow> rows,
    Map<String, dynamic> domain,
    String primaryType,
  ) {
    final domainName = domain["name"]?.toString();
    if (domainName != null && domainName.isNotEmpty) {
      rows.add(WCDecodedRow(label: S.current.wc_domain, value: domainName));
    }
    final chainId = domain["chainId"]?.toString();
    if (chainId != null && chainId.isNotEmpty) {
      rows.add(WCDecodedRow(label: S.current.chain_id, value: chainId));
    }
    final verifyingContract = domain["verifyingContract"]?.toString();
    if (verifyingContract != null && verifyingContract.isNotEmpty) {
      rows.add(
        WCDecodedRow(
          label: S.current.wc_verifying_contract,
          value: verifyingContract,
          kind: WCDecodedRowKind.address,
        ),
      );
    }
    if (primaryType.isNotEmpty) {
      rows.add(WCDecodedRow(label: S.current.wc_primary_type, value: primaryType));
    }
  }

  Future<WCDecodedRequest?> _decodePermitSemantics({
    required String primaryType,
    required Map<String, dynamic> domain,
    required Map<String, dynamic> message,
    required String rawFallback,
  }) async {
    final type = primaryType.toLowerCase();

    if (type == "permitsingle") {
      final details = (message["details"] as Map?)?.cast<String, dynamic>();
      if (details == null) {
        return null;
      }
      return _buildPermit2(
        detailsList: [details],
        domain: domain,
        spender: message["spender"]?.toString(),
        sigDeadline: _toBigInt(message["sigDeadline"]),
        rawFallback: rawFallback,
      );
    }

    if (type == "permitbatch") {
      final rawList = message["details"];
      if (rawList is! List) {
        return null;
      }
      final detailsList = rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false);
      if (detailsList.isEmpty) {
        return null;
      }
      return _buildPermit2(
        detailsList: detailsList,
        domain: domain,
        spender: message["spender"]?.toString(),
        sigDeadline: _toBigInt(message["sigDeadline"]),
        rawFallback: rawFallback,
      );
    }

    if (type == "permit" && message.containsKey("value") && message.containsKey("spender")) {
      return _buildEip2612(domain: domain, message: message, rawFallback: rawFallback);
    }

    return null;
  }

  List<WCDecodedRow> _signingContextRows(
    Map<String, dynamic> domain, {
    bool includeContract = true,
  }) {
    final rows = <WCDecodedRow>[];
    final chainId = domain["chainId"]?.toString();
    if (chainId != null && chainId.isNotEmpty) {
      rows.add(WCDecodedRow(label: S.current.chain_id, value: chainId));
    }
    final verifyingContract = domain["verifyingContract"]?.toString();
    if (includeContract && verifyingContract != null && verifyingContract.isNotEmpty) {
      rows.add(
        WCDecodedRow(
          label: S.current.wc_verifying_contract,
          value: verifyingContract,
          kind: WCDecodedRowKind.address,
        ),
      );
    }
    return rows;
  }

  Future<WCDecodedRequest> _buildPermit2({
    required List<Map<String, dynamic>> detailsList,
    required Map<String, dynamic> domain,
    required String? spender,
    required BigInt? sigDeadline,
    required String rawFallback,
  }) async {
    final rows = <WCDecodedRow>[];
    bool unreadableAmount = false;

    for (final details in detailsList) {
      final tokenAddress = details["token"]?.toString();
      final amount = _toBigInt(details["amount"]);
      final expiration = _toBigInt(details["expiration"]);

      if (tokenAddress != null && tokenAddress.isNotEmpty) {
        final token = await _safeResolve(tokenAddress);
        final symbol = tokenResolver.symbolOrShort(token, tokenAddress);
        rows.add(
          WCDecodedRow(
            label: S.current.wc_token,
            value: tokenResolver.displayName(token, symbol),
          ),
        );
        if (amount != null) {
          final amountStr = tokenResolver.formatAmount(amount, token);
          rows.add(
            WCDecodedRow(
              label: S.current.wc_amount,
              value: "$amountStr $symbol",
              kind: WCDecodedRowKind.amount,
            ),
          );
        }
      } else if (amount != null) {
        rows.add(
          WCDecodedRow(
            label: S.current.wc_amount,
            value: amount.toString(),
            kind: WCDecodedRowKind.amount,
          ),
        );
      }

      // A number too large for an int arrives from the JSON as a double and
      // cannot be read back exactly. Say so rather than dropping the row, which
      // would hide both the amount and the unlimited warning that goes with it.
      if (amount == null && details["amount"] != null) {
        unreadableAmount = true;
        rows.add(
          WCDecodedRow(
            label: S.current.wc_amount,
            value: S.current.wc_decode_failed,
            kind: WCDecodedRowKind.amount,
          ),
        );
      }

      if (expiration != null) {
        rows.add(
          WCDecodedRow(
            label: S.current.wc_expiration,
            value: tokenResolver.formatTimestamp(expiration),
          ),
        );
      }
    }

    if (spender != null && spender.isNotEmpty) {
      rows.add(
        WCDecodedRow(
          label: S.current.wc_approved_spender,
          value: spender,
          kind: WCDecodedRowKind.address,
        ),
      );
    }
    if (sigDeadline != null) {
      rows.add(
        WCDecodedRow(
          label: S.current.wc_signature_valid_until,
          value: tokenResolver.formatTimestamp(sigDeadline),
        ),
      );
    }
    rows.addAll(_signingContextRows(domain));

    final unlimited = detailsList.any((d) {
      final a = _toBigInt(d["amount"]);
      return a != null && tokenResolver.isUnlimitedAmount(a);
    });

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_permit2,
      actionSubtitle: "Permit2",
      rows: rows,
      warnings: [
        S.current.wc_warning_permit_review,
        if (unlimited) S.current.wc_warning_unlimited_approval,
        if (unreadableAmount) S.current.wc_warning_typed_data_invalid,
      ],
      hideTo: true,
      hideValue: true,
      rawFallback: rawFallback,
    );
  }

  Future<WCDecodedRequest> _buildEip2612({
    required Map<String, dynamic> domain,
    required Map<String, dynamic> message,
    required String rawFallback,
  }) async {
    final rows = <WCDecodedRow>[];
    final tokenAddress = domain["verifyingContract"]?.toString();
    final amount = _toBigInt(message["value"]);
    final spender = message["spender"]?.toString();
    final deadline = _toBigInt(message["deadline"]);

    if (tokenAddress != null && tokenAddress.isNotEmpty) {
      final token = await _safeResolve(tokenAddress);
      final symbol = tokenResolver.symbolOrShort(token, tokenAddress);
      rows.add(
        WCDecodedRow(
          label: S.current.wc_token,
          value: tokenResolver.displayName(token, symbol),
        ),
      );
      if (amount != null) {
        final amountStr = tokenResolver.formatAmount(amount, token);
        rows.add(
          WCDecodedRow(
            label: S.current.wc_amount,
            value: "$amountStr $symbol",
            kind: WCDecodedRowKind.amount,
          ),
        );
      }
    } else if (amount != null) {
      rows.add(
        WCDecodedRow(
          label: S.current.wc_amount,
          value: amount.toString(),
          kind: WCDecodedRowKind.amount,
        ),
      );
    }

    final unreadableAmount = amount == null && message["value"] != null;
    if (unreadableAmount) {
      rows.add(
        WCDecodedRow(
          label: S.current.wc_amount,
          value: S.current.wc_decode_failed,
          kind: WCDecodedRowKind.amount,
        ),
      );
    }

    if (spender != null && spender.isNotEmpty) {
      rows.add(
        WCDecodedRow(
          label: S.current.wc_approved_spender,
          value: spender,
          kind: WCDecodedRowKind.address,
        ),
      );
    }
    if (deadline != null) {
      rows.add(
        WCDecodedRow(
          label: S.current.wc_signature_valid_until,
          value: tokenResolver.formatTimestamp(deadline),
        ),
      );
    }
    rows.addAll(_signingContextRows(domain, includeContract: false));

    final unlimited = amount != null && tokenResolver.isUnlimitedAmount(amount);
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_permit,
      actionSubtitle: domain["name"]?.toString(),
      rows: rows,
      warnings: [
        S.current.wc_warning_permit_review,
        if (unlimited) S.current.wc_warning_unlimited_approval,
        if (unreadableAmount) S.current.wc_warning_typed_data_invalid,
      ],
      hideTo: true,
      hideValue: true,
      rawFallback: rawFallback,
    );
  }

  Future<Erc20Token?> _safeResolve(String contractAddress) async {
    try {
      return await tokenResolver.resolve(contractAddress);
    } catch (e) {
      printV("TypedDataDecoder: token resolve threw for $contractAddress: $e");
      return null;
    }
  }

  WCDecodedRequest? _decodeLegacyV1(dynamic raw) {
    List<dynamic>? entries;
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      entries = raw;
    } else if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
          entries = decoded;
        }
      } catch (_) {
        return null;
      }
    }
    if (entries == null) {
      return null;
    }

    final rows = <WCDecodedRow>[];
    for (final entry in entries) {
      if (entry is! Map) {
        return null;
      }
      final name = entry["name"]?.toString();
      final value = entry["value"];
      if (name == null || name.isEmpty) {
        return null;
      }
      rows.add(
        WCDecodedRow(
          label: name,
          value: _formatLeaf(name, value),
          kind: _looksLikeAddress(entry["type"]?.toString() ?? "", value)
              ? WCDecodedRowKind.address
              : WCDecodedRowKind.text,
        ),
      );
    }

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_sign_typed_data,
      rows: rows,
      hideTo: true,
      hideValue: true,
      rawFallback: const JsonEncoder.withIndent("  ").convert(entries),
    );
  }

  Map<String, dynamic>? _parsePayload(dynamic raw) {
    try {
      if (raw is Map) {
        return raw.cast<String, dynamic>();
      }
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.cast<String, dynamic>();
        }
      }
      if (raw is List && raw.length >= 2 && raw[1] is String) {
        final decoded = jsonDecode(raw[1] as String);
        if (decoded is Map) {
          return decoded.cast<String, dynamic>();
        }
      }
    } catch (e) {
      printV("TypedDataDecoder: failed to parse payload: $e");
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
        out.add(
          WCDecodedRow(
            label: prefix.isEmpty ? entry.key : "$prefix.${entry.key}",
            value: _formatLeaf(entry.key, entry.value),
          ),
        );
      }
      return out;
    }

    for (final field in fields) {
      final name = field["name"]?.toString() ?? "";
      final fieldType = field["type"]?.toString() ?? "";
      final value = message[name];
      if (value == null) {
        continue;
      }
      final label = prefix.isEmpty ? name : "$prefix.$name";

      if (types.containsKey(fieldType) && value is Map) {
        out.addAll(
          _flattenMessage(
            value.cast<String, dynamic>(),
            types,
            fieldType,
            prefix: label,
          ),
        );
      } else if (fieldType.endsWith("]") && value is List) {
        out.add(WCDecodedRow(label: label, value: "[${value.length}]"));
        for (var i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is Map) {
            final innerType = fieldType.substring(0, fieldType.lastIndexOf("["));
            if (types.containsKey(innerType)) {
              out.addAll(
                _flattenMessage(
                  item.cast<String, dynamic>(),
                  types,
                  innerType,
                  prefix: "$label[$i]",
                ),
              );
              continue;
            }
          }
          out.add(WCDecodedRow(label: "$label[$i]", value: _formatLeaf(name, item)));
        }
      } else {
        out.add(
          WCDecodedRow(
            label: label,
            value: _formatLeaf(name, value),
            kind: _looksLikeAddress(fieldType, value)
                ? WCDecodedRowKind.address
                : WCDecodedRowKind.text,
          ),
        );
      }
    }
    return out;
  }

  String _formatLeaf(String fieldName, dynamic value) {
    if (_timestampFieldNames.contains(fieldName.toLowerCase())) {
      final ts = _toBigInt(value);
      if (ts != null) {
        final formatted = tokenResolver.formatTimestamp(ts);
        if (formatted != ts.toString()) {
          return formatted;
        }
      }
    }
    return _stringifyValue(value);
  }

  bool _looksLikeAddress(String fieldType, dynamic value) {
    if (fieldType == "address") {
      return true;
    }
    if (value is String && value.length == 42 && value.startsWith("0x")) {
      return true;
    }
    return false;
  }

  String _stringifyValue(dynamic value) {
    if (value == null) {
      return "";
    }
    if (value is Map || value is List) {
      try {
        return jsonEncode(value);
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }

  BigInt? _toBigInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return BigInt.from(value);
    }
    if (value is BigInt) {
      return value;
    }
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) {
        return null;
      }
      if (s.toLowerCase().startsWith("0x")) {
        return BigInt.tryParse(s.substring(2), radix: 16);
      }
      return BigInt.tryParse(s);
    }
    return null;
  }
}
