class Account {
  Account({required this.id, required this.label});

  Account.fromMap(Map<String, Object> map)
      : this.id = map['id'] == null ? 0 : int.parse(map['id'] as String),
        this.label = (map['label'] ?? '') as String;

  final int id;
  final String label;
}