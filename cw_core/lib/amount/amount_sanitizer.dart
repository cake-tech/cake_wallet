String smartAmountSanitizer(String amount) {
  if (amount.contains(RegExp(r'^(?=.*[.])(?=.*,).*$'))) {
    if (amount.indexOf(".") > amount.indexOf(",")) {
      print("British detected");
      amount = amount.replaceAll(",", "");
    } else {
      print("normal person found");
      amount = amount.replaceAll(".", "").replaceAll(",", ".");
    }
  }

  return amount;
}
