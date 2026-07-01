enum EVMSupportedMethods {
  ethSign,
  ethSignTransaction,
  ethSignTypedData,
  ethSignTypedDataV4,
  switchChain,
  addChain,
  personalSign,
  ethSendTransaction;

  String get name {
    switch (this) {
      case ethSign:
        return 'eth_sign';
      case ethSignTransaction:
        return 'eth_signTransaction';
      case ethSignTypedData:
        return 'eth_signTypedData';
      case ethSignTypedDataV4:
        return 'eth_signTypedData_v4';
      case switchChain:
        return 'wallet_switchEthereumChain';
      case addChain:
        return 'wallet_addEthereumChain';
      case personalSign:
        return 'personal_sign';
      case ethSendTransaction:
        return 'eth_sendTransaction';
    }
  }
}