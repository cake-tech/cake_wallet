class OpenCryptoPayException implements Exception {
  final String message;

  OpenCryptoPayException([this.message = '']);

  @override
  String toString() =>
      'OpenCryptoPayException${message.isNotEmpty ? ': $message' : ''}';
}

class OpenCryptoPayNotSupportedException extends OpenCryptoPayException {
  final String provider;

  OpenCryptoPayNotSupportedException(this.provider);

  @override
  String get message => "$provider does not support Open CryptoPay";
}
