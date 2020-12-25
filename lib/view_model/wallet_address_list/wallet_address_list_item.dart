import 'package:flutter/foundation.dart';
import 'package:cake_wallet/utils/list_item.dart';

class WalletAddressListItem extends ListItem {
  const WalletAddressListItem({@required this.address, @required this.isPrimary,
    this.name, this.id}) : super();

  final int id;
  final bool isPrimary;
  final String address;
  final String name;

  @override
  String toString() => name ?? address;
}