import "package:cake_wallet/core/address_resolver/parsed_address.dart";
import "package:cake_wallet/entities/contact.dart";
import "package:cake_wallet/src/screens/wallet_connect/utils/string_parsing.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_info.dart";

abstract class SwapAddress {
  const SwapAddress();

  String get address;

  String get displayName;
}

class ExternalSwapAddress extends SwapAddress {
  const ExternalSwapAddress(this.address);

  @override
  final String address;

  @override
  String get displayName =>
      "${address.safeSubString(0, 4)}...${address.safeSubString(address.length - 4, address.length)}";
}

class PayAnythingSwapAddress extends SwapAddress {
  const PayAnythingSwapAddress(this.parsedAddress, this.currency);

  final ParsedAddress parsedAddress;
  final CryptoCurrency currency;

  @override
  String get address => parsedAddress.parsedAddressByCurrencyMap[currency]!;

  @override
  String get displayName => "${parsedAddress.profileName} (${parsedAddress.addressSource.label})";
}

class InternalWalletSwapAddress extends SwapAddress {
  const InternalWalletSwapAddress(this.walletInfo);

  final WalletInfo walletInfo;

  @override
  String get address => walletInfo.address;

  @override
  String get displayName => walletInfo.name;
}

class InternalAccountSwapAddress extends SwapAddress {
  const InternalAccountSwapAddress(
      {required this.walletName, required this.accountName, required this.address});

  final String walletName;
  final String accountName;
  @override
  final String address;

  @override
  String get displayName => "${walletName} → ${accountName}";
}

class ContactSwapAddress extends SwapAddress {
  const ContactSwapAddress({required this.contact});

  final Contact contact;

  @override
  String get address => contact.address;

  @override
  String get displayName => contact.name;
}
