
import "package:cake_wallet/entities/contact.dart";
import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/src/screens/wallet_connect/utils/string_parsing.dart";
import "package:cw_core/wallet_base.dart";

abstract class SwapAddress {
  String get address;
  String get displayName;
}

class ExternalSwapAddress extends SwapAddress {
  ExternalSwapAddress({required this.address});

  @override
  final String address;

  @override
  String get displayName => "${address.safeSubString(0, 4)}...${address.safeSubString(address.length-4, address.length)}";
}

class CurrentSwapAddress extends SwapAddress {
  CurrentSwapAddress({required WalletBase wallet}) : _wallet = wallet;


  final WalletBase _wallet;

  @override
  String get address => _wallet.walletAddresses.addressForExchange;

  @override
  String get displayName => _wallet.name;
}

class ContactSwapAddress extends SwapAddress {
  ContactSwapAddress({required this.contact});

  final Contact contact;

  @override
  String get address => contact.address;

  @override
  String get displayName => contact.name;
}