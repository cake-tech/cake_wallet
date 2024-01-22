import 'package:cake_wallet/utils/list_item.dart';

class WalletAddressListItem extends ListItem {
  const WalletAddressListItem({
    required this.address,
    required this.isPrimary,
    this.id,
    this.name,
    this.txCount,
    this.balance,
    this.isChange = false})
    : super();

  final int? id;
  final bool isPrimary;
  final String address;
  final String? name;
  final int? txCount;
  final String? balance;
  final bool isChange;

  @override
  String toString() => name ?? address;
}