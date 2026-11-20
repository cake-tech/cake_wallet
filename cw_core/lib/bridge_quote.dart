import "package:cw_core/amount/money.dart";

class BridgeQuote {
  const BridgeQuote({
    required this.fee,
    required this.receiveAmount,
    required this.approvalSpender,
  });

  final Money fee;
  final Money receiveAmount;
  final String? approvalSpender;
}
