import 'package:cake_wallet/entities/pending_conversion.dart';
import 'package:cake_wallet/entities/conversion_status.dart';
import 'package:cw_core/transaction_info.dart';

class PendingConversionMatcher {
  /// True when [tx] is the real transaction record [pending] is standing in for. Matched by the
  /// SDK payment id ([tx.id] against [PendingConversion.paymentId]), falling back to
  /// [PendingConversion.paymentHash] for the self-transfer twin the SDK may record under a
  /// different id (see `ConversionTwinCollapser`) - AND [tx]'s conversion must have reached a
  /// terminal status. A same-id record that's still pending isn't a match yet: removing
  /// [pending] then would leave nothing showing while the SDK is still converting.
  static bool matches(PendingConversion pending, TransactionInfo tx) {
    final sameId = tx.id == pending.paymentId ||
        (pending.paymentHash != null && tx.additionalInfo["paymentHash"] == pending.paymentHash);
    if (!sameId) {
      return false;
    }

    final status = ConversionStatusUtils.fromAdditionalInfo(tx.additionalInfo);
    return status != null && status != ConversionStatus.pending;
  }
}
