class UnspentCoinsItem {
  UnspentCoinsItem({
    this.address,
    this.amount,
    this.isFrozen,
    this.note,
    this.isSending = true});

  final String address;
  final String amount;
  final bool isFrozen;
  final String note;
  final bool isSending;
}