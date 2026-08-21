import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/format_fixed.dart';
import 'package:cw_core/parse_fixed.dart';

BigInt transformAmount(BigInt source, int sourceDecimals, int targetDecimals) {
  if (sourceDecimals == targetDecimals) {
    return source;
  }

  if (sourceDecimals > targetDecimals) {
    return parseFixed(
      formatFixed(source, sourceDecimals).withMaxDecimals(targetDecimals),
      targetDecimals,
    );
  } else {
    return parseFixed(formatFixed(source, sourceDecimals), targetDecimals);
  }
}

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
