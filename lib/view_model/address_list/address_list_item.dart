import 'package:flutter/foundation.dart';
import 'package:cake_wallet/utils/list_item.dart';

class AddressListItem extends ListItem {
  const AddressListItem({@required this.address, this.name, this.id})
      : super();

  final int id;
  final String address;
  final String name;

  @override
  String toString() => name ?? address;
}