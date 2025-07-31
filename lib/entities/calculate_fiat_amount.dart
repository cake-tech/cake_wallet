String calculateFiatAmount({double? price, String? cryptoAmount}) {
  if (price == null || cryptoAmount == null) {
    return '0.00';
  }

  cryptoAmount = cryptoAmount.replaceAll(',', '.');

  final _amount = double.parse(cryptoAmount);
  final _result = price * _amount;
  final result = _result < 0 ? _result * -1 : _result;

  if (result == 0.0) {
    return '0.00';
  }

  var formatted = '';
  final parts = result.toString().split('.');

  if (parts.length >= 2) {
    if (parts[1].length > 2) {
      formatted = formatWithCommas(parts[0] + '.' + parts[1].substring(0, 2));
    } else {
      formatted = formatWithCommas(parts[0] + '.' + parts[1]);
    }
  } else {
    formatted = formatWithCommas(parts[0]);
  }

  return result > 0.01 ? formatted : '< 0.01';
}

String formatWithCommas(String? number) {
  if (number?.isEmpty ?? true) return '';

  final parts = number!.split('.');
  final integerPart = parts[0];
  final decimalPart = parts.length > 1 ? parts[1] : '';

  final formattedInteger = integerPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match match) => ',',
  );

  return decimalPart.isNotEmpty ? '$formattedInteger.$decimalPart' : formattedInteger;
}
