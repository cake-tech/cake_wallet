class Subaddress {
  Subaddress({
    required this.id,
    required this.address,
    required this.label,
    this.balance = null,
    this.txCount = null,
  });

  Subaddress.fromMap(Map<String, Object?> map)
      : this.id = map['id'] == null ? 0 : int.parse(map['id'] as String),
        this.address = (map['address'] ?? '') as String,
        this.label = (map['label'] ?? '') as String,
        this.balance = (map['balance'] ?? '') as String?,
        this.txCount = (map['txCount'] ?? '') as int?;

  final int id;
  final String address;
  final String label;
  final String? balance;
  final int? txCount;
}
