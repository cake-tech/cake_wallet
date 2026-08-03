String _smartAmountSanitizer(String amount) {
  if (amount.contains(RegExp(r'^(?=.*[.])(?=.*,).*$'))) {
    if (amount.indexOf(".") > amount.indexOf(",")) {
      amount = amount.replaceAll(",", "");
    } else {
      amount = amount.replaceAll(".", "");
    }
  }

  return amount.replaceAll(",", ".");
}

extension SanitizerUserAmounts on String {
  String sanitized() => _smartAmountSanitizer(this);
}
