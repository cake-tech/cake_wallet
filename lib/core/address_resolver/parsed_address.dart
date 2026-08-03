import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cw_core/crypto_currency.dart';

class ParsedAddress {
  const ParsedAddress({
    required this.parsedAddressByCurrencyMap,
    this.addressSource = AddressSource.notParsed,
    this.handle = '',
    this.profileImageUrl = '',
    this.profileName = '',
    this.description = '',
    this.bip353DnsProof,
  });

  final Map<CryptoCurrency, String> parsedAddressByCurrencyMap;
  final AddressSource addressSource;
  final String handle;
  final String profileImageUrl;
  final String profileName;
  final String description;
  final String? bip353DnsProof;
}
