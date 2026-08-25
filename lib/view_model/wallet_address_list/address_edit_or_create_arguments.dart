import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';

/// Arguments for the Address Edit/Create page
class AddressEditOrCreateArguments {
  /// The item to edit. If null, we're creating a new address.
  final WalletAddressListItem? item;

  /// If true, create a shielded address (e.g., PIVX Sapling).
  /// Only relevant when creating new addresses (item == null).
  final bool isShielded;

  AddressEditOrCreateArguments({
    this.item,
    this.isShielded = false,
  });
}
