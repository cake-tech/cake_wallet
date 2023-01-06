String formatAmount(String amount) {
  if ((!amount.contains('.'))&&(!amount.contains(','))) {
    return amount + '.00';
  }

  while (amount.endsWith('0')) {
    amount = amount.substring(0, amount.length - 1);
  }

  if ((amount.endsWith('.'))||(amount.endsWith(','))) {
    return amount + '00';
  }
  return amount;
}