class PendingTransactionDescription {
  PendingTransactionDescription(
      {required this.amount,
      required this.fee,
      required this.hash,
      required this.hex,
      required this.pointerAddress,
      required this.txCount});

  final int amount;
  final int fee;
  final String hash;
  final String hex;
  final int pointerAddress;
  final int txCount;
}
