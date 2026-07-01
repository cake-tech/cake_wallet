String formatAmount(String amount) {
  if ((!amount.contains('.'))&&(!amount.contains(','))) {
    return amount + '.00';
  } else if ((amount.endsWith('.'))||(amount.endsWith(','))) {
    return amount + '00';
  }
  return amount;
}