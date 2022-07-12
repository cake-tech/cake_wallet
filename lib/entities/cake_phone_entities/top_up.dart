class TopUp {
  const TopUp({this.id, this.address, this.amount});

  final String id;
  final String address;
  final double amount;

  @override
  bool operator ==(Object other) => other is TopUp && other.id == id;

  @override
  int get hashCode => id.hashCode;
}