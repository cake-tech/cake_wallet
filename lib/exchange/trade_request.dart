import 'package:cw_core/crypto_currency.dart';

class TradeRequest {
  TradeRequest(
      {required this.fromCurrency,
      required this.toCurrency,
      required this.toAddress,
      required this.refundAddress,
      required this.fromAmount,
      this.toAmount = '',
      this.toAddressExtraId = '',
      this.isFixedRate = false});

  final CryptoCurrency fromCurrency;
  final CryptoCurrency toCurrency;
  final String toAddress;
  final String refundAddress;
  final String fromAmount;
  final String toAmount;
  final String toAddressExtraId;
  final bool isFixedRate;
}
