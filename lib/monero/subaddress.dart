import 'package:cw_monero/structs/subaddress_row.dart';

class Subaddress {
  Subaddress({this.id, this.address, this.label});

  Subaddress.fromMap(Map map)
      : this.id = map['id'] == null ? 0 : int.parse(map['id'] as String),
        this.address = (map['address'] ?? '') as String,
        this.label = (map['label'] ?? '') as String;

  Subaddress.fromRow(SubaddressRow row)
      : this.id = row.getId(),
        this.address = row.getAddress(),
        this.label = row.getLabel();

  final int id;
  final String address;
  final String label;
}
