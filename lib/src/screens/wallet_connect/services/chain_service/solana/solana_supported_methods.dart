enum SolanaSupportedMethods {
  solSignMessage,
  solSignTransaction,
  solSignAllTransaction;

  String get name {
    switch (this) {
      case solSignMessage:
        return 'solana_signMessage';
      case solSignTransaction:
        return 'solana_signTransaction';
      case solSignAllTransaction:
        return 'solana_signAllTransactions';
    }
  }
}
