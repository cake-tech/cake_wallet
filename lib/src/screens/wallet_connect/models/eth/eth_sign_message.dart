enum WCSignType {
  message,
  personalMessage,
  typedMessageV2,
  typedMessageV3,
  typedMessageV4,
}

class EthereumSignMessage {
  final String data;
  final String address;
  final WCSignType type;

  const EthereumSignMessage({
    required this.data,
    required this.address,
    required this.type,
  });
}