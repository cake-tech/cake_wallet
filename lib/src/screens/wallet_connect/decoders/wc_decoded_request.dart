import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class WCDecodedRequest {
  const WCDecodedRequest({
    required this.actionTitle,
    this.actionSubtitle,
    this.rows = const [],
    this.detailRows = const [],
    this.warnings = const [],
    this.hideValue = false,
    this.hideTo = false,
    this.rawFallback,
  });

  final String actionTitle;
  final String? actionSubtitle;

  final List<WCDecodedRow> rows;
  final List<WCDecodedRow> detailRows;
  final List<String> warnings;
  final bool hideValue;
  final bool hideTo;

  final String? rawFallback;

  WCDecodedRequest copyWith({
    String? actionTitle,
    String? actionSubtitle,
    List<WCDecodedRow>? rows,
    List<WCDecodedRow>? detailRows,
    List<String>? warnings,
    bool? hideValue,
    bool? hideTo,
    String? rawFallback,
  }) =>
      WCDecodedRequest(
        actionTitle: actionTitle ?? this.actionTitle,
        actionSubtitle: actionSubtitle ?? this.actionSubtitle,
        rows: rows ?? this.rows,
        detailRows: detailRows ?? this.detailRows,
        warnings: warnings ?? this.warnings,
        hideValue: hideValue ?? this.hideValue,
        hideTo: hideTo ?? this.hideTo,
        rawFallback: rawFallback ?? this.rawFallback,
      );
}
