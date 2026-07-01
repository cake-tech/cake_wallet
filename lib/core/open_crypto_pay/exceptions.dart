class OpenCryptoPayException implements Exception {
  final String message;

  OpenCryptoPayException([this.message = '']);

  @override
  String toString() => message.isNotEmpty ? message : 'OpenCryptoPayException';
}

class OpenCryptoPayNotSupportedException extends OpenCryptoPayException {
  final String provider;

  OpenCryptoPayNotSupportedException(this.provider);

  @override
  String get message => "$provider does not support Open CryptoPay";
}
