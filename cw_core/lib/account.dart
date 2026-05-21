class Account {
  Account({
    required this.id,
    required this.label,
    String? balance,
  }) : balance = balance ?? '0.00';

  Account.fromMap(Map<String, Object?> map)
      : id = map['id'] is int
      ? map['id'] as int
      : int.tryParse(map['id']?.toString() ?? '') ?? 0,
        label = (map['label'] ?? '') as String,
        balance = (map['balance'] ?? '0.00') as String;

  final int id;
  final String label;
  final String balance;

  Account copyWith({
    int? id,
    String? label,
    String? balance,
  }) {
    return Account(
      id: id ?? this.id,
      label: label ?? this.label,
      balance: balance ?? this.balance,
    );
  }

  Map<String, Object> toMap() {
    return {
      'id': id.toString(),
      'label': label,
      'balance': balance,
    };
  }
}