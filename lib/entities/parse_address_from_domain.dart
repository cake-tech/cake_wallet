import 'package:cake_wallet/core/yat_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/entities/unstoppable_domain_address.dart';
import 'package:cake_wallet/entities/emoji_string_extension.dart';

class ParseAddressFromDomain {
  
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

Future<ParsedAddress> parse(String text, String ticker) async {
    try {
        if (text.hasOnlyEmojis) {
        final yatService = getIt.get<YatService>();
        final addresses = await yatService.fetchYatAddress(text, ticker);
        if (addresses?.isEmpty ?? true) {
          return ParsedAddress(
              addresses: [text], parseFrom: ParseFrom.yatRecord);
        }
        return ParsedAddress(
            addresses: addresses.map((e) => e.address).toList(),
            name: text,
            parseFrom: ParseFrom.yatRecord,
          );
      }
      final formattedName = OpenaliasRecord.formatDomainName(text);
      final domainParts = formattedName.split('.');
      final name = domainParts.last;

      if (domainParts.length <= 1 || domainParts.first.isEmpty || name.isEmpty) {
        return ParsedAddress(addresses: [text]);
      }

      if (unstoppableDomains.any((domain) => name.contains(domain))) {
        final address = await fetchUnstoppableDomainAddress(text, ticker);

        if (address?.isEmpty ?? true) {
          return ParsedAddress(addresses: [text]);
        }

        return ParsedAddress(
            addresses: [address],
            name: text,
            parseFrom: ParseFrom.unstoppableDomains);
      }

      final record = await OpenaliasRecord.fetchAddressAndName(
          formattedName: formattedName, ticker: ticker);

      if (record == null || record.address.contains(formattedName)) {
        return ParsedAddress(addresses: [text]);
      }

      return ParsedAddress(
          addresses: [record.address],
          name: record.name,
          description: record.description,
          parseFrom: ParseFrom.openAlias);
    } catch (e) {
      print(e.toString());
    }

    return ParsedAddress(addresses: [text]);
  }
}


