enum TronSupportedMethods {
  tronSignMessage,
  tronSignTransaction;

  String get name {
    switch (this) {
      case tronSignMessage:
        return "tron_signMessage";
      case tronSignTransaction:
        return "tron_signTransaction";
    }
  }
}
