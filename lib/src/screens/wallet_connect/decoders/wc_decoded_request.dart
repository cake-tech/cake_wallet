import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class WCDecodedRequest {
  const WCDecodedRequest({
    required this.actionTitle,
    this.actionSubtitle,
    this.rows = const [],
    this.detailRows = const [],
    this.warnings = const [],
    this.isValueShown = false,
    this.rawFallback,
  });

  WCDecodedRequest.signMessage(String message)
    : this(
        actionTitle: S.current.wc_action_sign_message,
        rows: [WCDecodedRow(label: S.current.wc_message_label, value: message)],
      );

  final String actionTitle;
  final String? actionSubtitle;

  final List<WCDecodedRow> rows;
  final List<WCDecodedRow> detailRows;
  final List<String> warnings;
  final bool isValueShown;

  final String? rawFallback;

  WCDecodedRequest copyWith({
    String? actionTitle,
    String? actionSubtitle,
    List<WCDecodedRow>? rows,
    List<String>? warnings,
    String? rawFallback,
  }) => WCDecodedRequest(
    actionTitle: actionTitle ?? this.actionTitle,
    actionSubtitle: actionSubtitle ?? this.actionSubtitle,
    rows: rows ?? this.rows,
    detailRows: detailRows,
    warnings: warnings ?? this.warnings,
    isValueShown: isValueShown,
    rawFallback: rawFallback ?? this.rawFallback,
  );
}
