import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

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

  Money get amount => Money.parse(rawAmount ?? "0", CryptoCurrency.btc, isBaseUnit: true);

  set amount(Money amount) => rawAmount = amount.toStringWithPrecision(useBaseUnit: true);
}

enum PayjoinSessionStatus {
  created,
  waiting,
  inProgress,
  success,
  cancelled,
  unrecoverable,
}

/// How an earlier send already used a payjoin endpoint. A BIP77 endpoint is
/// a single-use receiver mailbox, so a payment request whose `pj=` appears
/// here must not start another payjoin.
enum PayjoinEndpointUse {
  /// An earlier send is still open; finish it (or broadcast its fallback)
  /// instead of paying again.
  pending,

  /// An earlier send completed, by payjoin or by its fallback.
  paid,

  /// An earlier send was cancelled after its original transaction reached
  /// the receiver, who can still broadcast it.
  cancelled,
}
