class Account {
  Account({this.id, this.label});

  Account.fromMap(Map map)
      : this.id = map['id'] == null ? 0 : int.parse(map['id'] as String),
        this.label = (map['label'] ?? '') as String;

  final int? id;
  final String? label;
}