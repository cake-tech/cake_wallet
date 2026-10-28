class PayjoinSession {
  PayjoinSession({
    required this.walletId,
    this.receiver,
    this.sender,
    this.pjUri,
    this.status = "created",
    this.inProgressSince,
    this.rawAmount,
  }) {
    if (receiver == null) {
      assert(sender != null);
      assert(pjUri != null);
    } else {
      assert(receiver != null);
    }
  }

  final String walletId;

  final String? sender;

  final String? receiver;

  final String? pjUri;

  String status;

  DateTime? inProgressSince;

  String? txId;

  String? rawAmount;

  String? error;

  String? originalPsbt;

  bool usedFallback = false;

  String? recipientAddress;

  bool get isSenderSession => sender != null;

  BigInt get amount => BigInt.parse(rawAmount ?? "0");
  set amount(BigInt amount) => rawAmount = amount.toString();
}

enum PayjoinSessionStatus {
  created,
  waiting,
  inProgress,
  success,
  cancelled,
  unrecoverable,
}
