
class PendingTransactionDescription {
  PendingTransactionDescription({
    required this.amount,
    required this.fee,
    required this.hash,
    required this.hex,
    required this.txKey,
    required this.pointerAddress});

  final int amount;
  final int fee;
  final String hash;
  final String hex;
  final String txKey;
  final int pointerAddress;
}