import 'package:cake_wallet/core/yat_service.dart';
import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/entities/unstoppable_domain_address.dart';
import 'package:cake_wallet/entities/emoji_string_extension.dart';
import 'package:flutter/foundation.dart';

class AddressResolver {
  
  AddressResolver({@required this.yatService});
  
  final YatService yatService;
  
  static const unstoppableDomains = [
  'crypto',
  'zil',
  'x',
  'coin',
  'wallet',
  'bitcoin',
  '888',
  'nft',
  'dao',
  'blockchain'
];

  Future<ParsedAddress> resolve(String text, String ticker) async {
    try {
      if (text.hasOnlyEmojis) {
        final addresses = await yatService.fetchYatAddress(text, ticker);
        return ParsedAddress.fetchEmojiAddress(addresses: addresses, name: text);
      }
      final formattedName = OpenaliasRecord.formatDomainName(text);
      final domainParts = formattedName.split('.');
      final name = domainParts.last;

      if (domainParts.length <= 1 || domainParts.first.isEmpty || name.isEmpty) {
        return ParsedAddress(addresses: [text]);
      }

      if (unstoppableDomains.any((domain) => name.contains(domain))) {
        final address = await fetchUnstoppableDomainAddress(text, ticker);
        return ParsedAddress.fetchUnstoppableDomainAddress(address: address, name: text);
      }

      final record = await OpenaliasRecord.fetchAddressAndName(
          formattedName: formattedName, ticker: ticker);
      return ParsedAddress.fetchOpenAliasAddress(record: record, name: text);
      
    } catch (e) {
      print(e.toString());
    }

    return ParsedAddress(addresses: [text]);
  }
}
