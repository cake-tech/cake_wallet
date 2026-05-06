import 'package:cw_core/crypto_currency.dart';

class StarknetTransactionCreationException implements Exception {
  final String exceptionMessage;

  StarknetTransactionCreationException(CryptoCurrency currency)
      : exceptionMessage = 'Error creating ${currency.title} transaction.';

  StarknetTransactionCreationException.fromMessage(this.exceptionMessage);

  @override
  String toString() => exceptionMessage;
}

class StarknetTransactionWrongBalanceException implements Exception {
  final String exceptionMessage;

  StarknetTransactionWrongBalanceException(CryptoCurrency currency)
      : exceptionMessage =
            'Wrong balance. Not enough ${currency.title} on your balance.';

  @override
  String toString() => exceptionMessage;
}

class StarknetInsufficientFeeException implements Exception {
  final String exceptionMessage;

  StarknetInsufficientFeeException({double? requiredFee})
      : exceptionMessage = requiredFee != null
            ? 'Insufficient STRK for fees. Required: ~${requiredFee.toStringAsFixed(8)} STRK. '
                'Please add STRK to your wallet to cover transaction fees.'
            : 'Insufficient STRK for fees. '
                'Please add STRK to your wallet to cover transaction fees.';

  @override
  String toString() => exceptionMessage;
}

class StarknetInvalidAddressException implements Exception {
  final String address;

  StarknetInvalidAddressException(this.address);

  @override
  String toString() =>
      'Invalid Starknet address: $address. '
      'Address must be a hex string starting with 0x.';
}

class StarknetAccountNotDeployedException implements Exception {
  @override
  String toString() =>
      'Account is not deployed on Starknet. '
      'Please deploy your account before sending transactions.';
}

class StarknetProviderNotConnectedException implements Exception {
  @override
  String toString() => 'Starknet provider not connected. Please check your node connection.';
}

class StarknetNodeConnectionException implements Exception {
  final String exceptionMessage;

  StarknetNodeConnectionException([String? details])
      : exceptionMessage = details != null
            ? 'Failed to connect to Starknet node: $details'
            : 'Failed to connect to Starknet node.';

  @override
  String toString() => exceptionMessage;
}
