String smartAmountSanitizer(String amount) {
  if (amount.contains(RegExp(r'^(?=.*[.])(?=.*,).*$'))) {
    if (amount.indexOf(".") > amount.indexOf(",")) {
      amount = amount.replaceAll(",", "");
    } else {
      amount = amount.replaceAll(".", "").replaceAll(",", ".");
    }
  }

  return amount;
}
