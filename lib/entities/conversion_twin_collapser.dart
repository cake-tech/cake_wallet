import "package:cake_wallet/entities/conversion_status.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_info.dart";

/// Paying your own invoice or address (e.g. the self-invoice `LightningWallet
/// .prepareTokenToBitcoinConversion` pays to realize a token -> Bitcoin conversion) creates two
/// separate SDK payment records for what the user experiences as one event - an outgoing leg and
/// an incoming leg, sharing the same Lightning payment hash. Collapsing them here (presentation
/// only - nothing is deleted from storage) avoids showing two history rows.
class ConversionTwinCollapser {
  /// The ids of transactions to drop from a history list, picked from [transactions]. Only ever
  /// drops one half of a clean two-record pair that shares a pairing key (payment hash, or
  /// preimage for records from before payment hash was tagged) and has opposite directions -
  /// anything else (a lone transaction, more than two sharing a key, a same-direction pair, or a
  /// transaction with neither key present at all) passes through untouched.
  static Set<String> transactionIdsToDrop(Iterable<TransactionInfo> transactions) {
    final toDrop = <String>{};
    final byKey = <String, List<TransactionInfo>>{};

    for (final tx in transactions) {
      // The legs of a conversion that paid for a send: the send's own row already says what
      // happened. Kept while unfinished, so a failed conversion still shows (and can be refunded).
      if (_isCompletedSendFundingLeg(tx)) {
        toDrop.add(tx.id);
        continue;
      }

      final key = _pairingKey(tx);
      if (key == null) {
        continue;
      }

      byKey.putIfAbsent(key, () => []).add(tx);
    }

    for (final group in byKey.values) {
      // More (or fewer) than two sharing a key isn't the self-transfer shape this handles -
      // leave it alone rather than guess.
      if (group.length != 2) {
        continue;
      }

      final a = group[0];
      final b = group[1];
      if (a.direction == b.direction) {
        continue;
      }

      final incoming = a.direction == TransactionDirection.incoming ? a : b;
      final outgoing = identical(a, incoming) ? b : a;

      // Keep whichever carries the most conversion detail; on a tie, keep the incoming one - it's
      // what the user actually ended up holding.
      final keep = _tagRank(outgoing) > _tagRank(incoming) ? outgoing : incoming;
      final drop = identical(keep, incoming) ? outgoing : incoming;

      toDrop.add(drop.id);
    }

    return toDrop;
  }

  static bool _isCompletedSendFundingLeg(TransactionInfo tx) =>
      tx.additionalInfo["conversionPurpose"] == "ongoingPayment" &&
      ConversionStatusUtils.fromAdditionalInfo(tx.additionalInfo) == ConversionStatus.completed;

  static String? _pairingKey(TransactionInfo tx) {
    // Shared by both legs of a Stable Balance conversion, which carry no payment hash.
    final conversionId = tx.additionalInfo["conversionId"];

    if (conversionId is String) {
      return "conversion:$conversionId";
    }

    final hash = tx.additionalInfo["paymentHash"];

    if (hash is String) {
      return hash;
    }

    final preimage = tx.additionalInfo["preimage"];
    return preimage is String ? preimage : null;
  }

  /// 2: the SDK's full conversion details (with the step amounts); 1: just the asset tags, which
  /// in-flight legs also carry; 0: untagged.
  static int _tagRank(TransactionInfo tx) {
    if (tx.additionalInfo["conversionFromAmount"] != null) {
      return 2;
    }
    if (tx.additionalInfo["conversionToTicker"] != null) {
      return 1;
    }
    return 0;
  }
}
