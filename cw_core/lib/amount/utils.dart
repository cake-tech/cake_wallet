String trimTrailingFractionZeros(String value) {
  if (!value.contains('.')) {
    return value;
  }

  var end = value.length;
  while (end > 0 && value[end - 1] == "0") {
    end--;
  }

  final trimmed = end == value.length ? value : value.substring(0, end);
  return trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
}
