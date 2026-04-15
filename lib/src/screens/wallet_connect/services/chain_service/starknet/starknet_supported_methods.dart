enum StarknetSupportedMethods {
  signTypedData,
  requestAddInvokeTransaction;

  String get name {
    switch (this) {
      case StarknetSupportedMethods.signTypedData:
        return 'starknet_signTypedData';
      case StarknetSupportedMethods.requestAddInvokeTransaction:
        return 'starknet_requestAddInvokeTransaction';
    }
  }
}
