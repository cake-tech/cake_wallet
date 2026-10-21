import "package:cw_core/crypto_currency.dart";
import "package:cw_core/exceptions/cake_exception.dart";

class EVMChainMnemonicIsIncorrectException implements Exception {
  @override
  String toString() =>
      "EVM mnemonic has incorrect format. Mnemonic should contain 12 or 24 words separated by space.";
}

class EVMChainTransactionCreationException extends TransactionGenerationException {
  EVMChainTransactionCreationException(CryptoCurrency currency)
      : super("Wrong balance. Not enough ${currency.title} on your balance.");

  EVMChainTransactionCreationException.fromMessage(super.message);
}

class EVMChainTransactionFeesException extends TransactionGenerationException {
  EVMChainTransactionFeesException(super.message);

  EVMChainTransactionFeesException.fromCurrency(String currency)
      : super("Transaction failed due to insufficient $currency balance to cover the fees.");
}

class InsufficientGasFeeException extends TransactionGenerationException {
  InsufficientGasFeeException({
    this.requiredGasFee,
    this.currentBalance,
  }) : super(_buildMessage(requiredGasFee, currentBalance));
  final BigInt? requiredGasFee;
  final BigInt? currentBalance;

  static String _buildMessage(BigInt? requiredGasFee, BigInt? currentBalance) {
    const baseMessage = "Insufficient ETH for gas fees.";
    const addEthMessage = " Please add ETH to your wallet to cover transaction fees.";

    if (requiredGasFee != null) {
      final requiredEth = (requiredGasFee / BigInt.from(10).pow(18)).toStringAsFixed(8);
      final balanceInfo = currentBalance != null
          ? ", Available: ${(currentBalance / BigInt.from(10).pow(18)).toStringAsFixed(8)} ETH"
          : "";
      return "$baseMessage Required: ~$requiredEth ETH$balanceInfo.$addEthMessage";
    }

    return "$baseMessage$addEthMessage";
  }
}
