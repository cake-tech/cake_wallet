import 'package:cw_monero/api/structs/account_row.dart';

class Account {
  Account({this.id, this.label});

  Account.fromMap(Map map)
      : this.id = map['id'] == null ? 0 : int.parse(map['id'] as String),
        this.label = (map['label'] ?? '') as String;

  Account.fromRow(AccountRow row)
      : this.id = row.getId(),
        this.label = row.getLabel();

  final int id;
  final String label;
}
