import 'package:flutter/foundation.dart';
import 'package:cake_wallet/utils/list_item.dart';

class WalletAddressListItem extends ListItem {
  const WalletAddressListItem({
    required this.address,
    required this.isPrimary,
    this.id,
    this.name,
    this.isChange = false,
    this.legacyAddress = ''})
    : super();

  final int? id;
  final bool isPrimary;
  final String address;
  final String? name;
  final bool isChange;
  final String? legacyAddress;

  @override
  String toString() => name ?? address;
}