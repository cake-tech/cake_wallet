double cryptoAmountToDouble({required num amount, required num divider}) => amount / divider;

extension MaxDecimals on String {
  String withMaxDecimals(int maxDecimals) {
    var parts = split(".");

    if (parts.length > 2) {
      parts = [parts.first, parts.sublist(1, parts.length).join("")];
    }

    if (parts.length == 2 && parts[1].length > maxDecimals) {
      parts[1] = parts[1].substring(0, maxDecimals);
    }

    return parts.join(".");
  }
}
