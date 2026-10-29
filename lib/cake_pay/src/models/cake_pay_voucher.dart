enum CakePayVoucherValueKind { cardNumber, code, redemptionLink }

class CakePayVoucher {
  const CakePayVoucher({
    required this.cardId,
    this.code,
    this.url,
    this.pin,
    this.cardNumber,
    this.cvv,
    this.redemptionInstructions,
    this.expirationDate,
    this.validityDate,
  });

  factory CakePayVoucher.fromMap(Map<String, dynamic> map) => CakePayVoucher(
        cardId: map["card_id"] as int?,
        code: map["code"] as String?,
        url: map["url"] as String?,
        pin: map["pin"] as String?,
        cardNumber: map["cardNumber"] as String?,
        cvv: map["cvv"] as String?,
        redemptionInstructions: map["redemption_instructions"] as String?,
        expirationDate: map["expirationDate"] as String?,
        validityDate: map["validityDate"] as String?,
      );

  final int? cardId;
  final String? code;
  final String? url;
  final String? pin;
  final String? cardNumber;
  final String? cvv;
  final String? redemptionInstructions;
  final String? expirationDate;
  final String? validityDate;

  /// The main value to present to the user: card number, falling back to the gift code, then to
  /// the redemption URL.
  String? get primaryValue => _firstNonEmpty([cardNumber, code, url]);

  /// What [primaryValue] holds, so the UI can label it.
  CakePayVoucherValueKind get primaryValueKind {
    if (_firstNonEmpty([cardNumber]) != null) {
      return CakePayVoucherValueKind.cardNumber;
    }

    if (_firstNonEmpty([code]) != null) {
      return CakePayVoucherValueKind.code;
    }

    return CakePayVoucherValueKind.redemptionLink;
  }

  static List<CakePayVoucher> listFromJson(dynamic json) {
    if (json is! List) {
      return const [];
    }
    return json
        .map((e) => CakePayVoucher.fromMap(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

enum CakePayRedemptionBlockReason {
  vpnOrProxy("VPN_OR_PROXY_BLOCKED"),
  bannedLocation("BANNED_LOCATION");

  const CakePayRedemptionBlockReason(this.apiValue);

  final String apiValue;

  static CakePayRedemptionBlockReason? fromApi(String? value) {
    for (final reason in values) {
      if (reason.apiValue == value) {
        return reason;
      }
    }
    return null;
  }
}

/// Result of `GET /api/orders/redemption/<token>/`.
///
/// [allowed] is false when the security check failed (403) or the codes are not ready yet (200);
/// [message] is meant to be shown to the user as is.
class CakePayRedemption {
  const CakePayRedemption({
    required this.allowed,
    required this.vouchers,
    this.message,
    this.blockReason,
  });

  factory CakePayRedemption.fromMap(Map<String, dynamic> map) => CakePayRedemption(
        allowed: map["allowed"] as bool? ?? false,
        message: map["message"] as String?,
        blockReason: CakePayRedemptionBlockReason.fromApi(map["error_code"] as String?),
        vouchers: CakePayVoucher.listFromJson(map["vouchers_list"]),
      );

  final bool allowed;
  final List<CakePayVoucher> vouchers;
  final String? message;
  final CakePayRedemptionBlockReason? blockReason;
}
