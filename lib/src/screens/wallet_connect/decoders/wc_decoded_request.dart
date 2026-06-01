import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart';

class WCDecodedRequest {
  const WCDecodedRequest({
    required this.actionTitle,
    this.actionSubtitle,
    this.rows = const [],
    this.warnings = const [],
    this.hideZeroValue = false,
    this.hideTo = false,
    this.rawFallback,
  });

  final String actionTitle;
  final String? actionSubtitle;
  final List<WCDecodedRow> rows;
  final List<String> warnings;

  final bool hideZeroValue;
  final bool hideTo;

  final String? rawFallback;

  WCDecodedRequest copyWith({
    String? actionTitle,
    String? actionSubtitle,
    List<WCDecodedRow>? rows,
    List<String>? warnings,
    bool? hideZeroValue,
    bool? hideTo,
    String? rawFallback,
  }) {
    return WCDecodedRequest(
      actionTitle: actionTitle ?? this.actionTitle,
      actionSubtitle: actionSubtitle ?? this.actionSubtitle,
      rows: rows ?? this.rows,
      warnings: warnings ?? this.warnings,
      hideZeroValue: hideZeroValue ?? this.hideZeroValue,
      hideTo: hideTo ?? this.hideTo,
      rawFallback: rawFallback ?? this.rawFallback,
    );
  }
}
