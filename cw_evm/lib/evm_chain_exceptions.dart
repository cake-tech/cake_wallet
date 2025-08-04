import 'package:cw_core/crypto_currency.dart';

class EVMChainTransactionCreationException implements Exception {
  final String exceptionMessage;

  EVMChainTransactionCreationException(CryptoCurrency currency)
      : exceptionMessage = 'Wrong balance. Not enough ${currency.title} on your balance.';

  EVMChainTransactionCreationException.fromMessage(this.exceptionMessage);

  @override
  String toString() => exceptionMessage;
}


class EVMChainTransactionFeesException implements Exception {
  final String exceptionMessage;

  EVMChainTransactionFeesException(String currency)
      : exceptionMessage = 'Transaction failed due to insufficient $currency balance to cover the fees.';

  @override
  String toString() => exceptionMessage;
}

class InsufficientGasFeeException implements Exception {
  final String exceptionMessage;
  final BigInt? requiredGasFee;
  final BigInt? currentBalance;

  InsufficientGasFeeException({
    this.requiredGasFee,
    this.currentBalance,
  }) : exceptionMessage = _buildMessage(requiredGasFee, currentBalance);

  static String _buildMessage(BigInt? requiredGasFee, BigInt? currentBalance) {
    const baseMessage = 'Insufficient ETH for gas fees.';
    const addEthMessage = ' Please add ETH to your wallet to cover transaction fees.';
    
    if (requiredGasFee != null) {
      final requiredEth = (requiredGasFee / BigInt.from(10).pow(18)).toStringAsFixed(8);
      final balanceInfo = currentBalance != null 
          ? ', Available: ${(currentBalance / BigInt.from(10).pow(18)).toStringAsFixed(8)} ETH'
          : '';
      return '$baseMessage Required: ~$requiredEth ETH$balanceInfo.$addEthMessage';
    }
    
    return '$baseMessage$addEthMessage';
  }

  @override
  String toString() => exceptionMessage;
}
