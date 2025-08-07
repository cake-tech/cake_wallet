import 'calculate_fiat_amount.dart';

String formatAmount(String amount) {
  if ((!amount.contains('.'))&&(!amount.contains(','))) {
    return formatWithCommas(amount + '.00');
  } else if ((amount.endsWith('.'))||(amount.endsWith(','))) {
    return formatWithCommas(amount + '00');
  }
  return formatWithCommas(amount);
}