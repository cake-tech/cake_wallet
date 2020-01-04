import 'package:cw_monero/structs/account_row.dart';

class Account {
  final int id;
  final String label;

  Account({this.id, this.label});

  Account.fromMap(Map map)
      : this.id = map['id'] == null ? 0 : int.parse(map['id']),
        this.label = map['label'] ?? '';

  Account.fromRow(AccountRow row)
      : this.id = row.getId(),
        this.label = row.getLabel();
}
