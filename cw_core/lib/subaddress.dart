class Subaddress {
  Subaddress({required this.id, required this.address, required this.label});

  Subaddress.fromMap(Map<String, Object?> map)
      : this.id = map['id'] == null ? 0 : int.parse(map['id'] as String),
        this.address = (map['address'] ?? '') as String,
        this.label = (map['label'] ?? '') as String;

  final int id;
  final String address;
  final String label;
}
