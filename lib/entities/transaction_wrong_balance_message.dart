import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/exceptions.dart';

/// Formats the wallet's exact affordability calculation, including when no
/// pending transaction was built. Missing metadata retains the legacy message.
String transactionWrongBalanceMessage(
  TransactionWrongBalanceException error, {
  bool useBaseUnit = false,
}) {
  final message = S.current.tx_wrong_balance_exception(error.currency.toString());
  final required = error.requiredBalance;
  final available = error.availableBalance;
  if (required == null ||
      available == null ||
      required.currency != error.currency ||
      available.currency != error.currency ||
      required.isNegative ||
      available.isNegative ||
      required <= available) {
    return message;
  }

  // Full precision keeps even a one-base-unit shortfall visible.
  String format(Money value) => value.toStringWithSymbol(useBaseUnit: useBaseUnit);
  final details = <String>[];
  final fee = error.fee;
  if (fee != null && fee.currency == error.currency && !fee.isNegative && fee <= required) {
    final principal = required - fee;
    // A token swap or approval can require native gas only. Its zero native
    // call value must not be displayed as the token source amount.
    if (!principal.isZero) {
      details.add('${S.current.transaction_details_amount}: ${format(principal)}');
    }
    details.add('${S.current.wc_max_network_fee}: ${format(fee)}');
    if (error.feePriority != null) {
      details.add('${S.current.settings_fee_priority}: ${error.feePriority}');
    }
  }
  details.addAll([
    '${S.current.transaction_cost}: ${format(required)}',
    '${S.current.available_balance}: ${format(available)}',
    '${S.current.overshot}: ${format(required - available)}',
  ]);
  return '$message\n\n${details.join('\n')}';
}
