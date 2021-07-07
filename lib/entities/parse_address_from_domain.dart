import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/entities/unstoppable_domain_address.dart';

const topLevelDomain = 'crypto';

Future<ParsedAddress> parseAddressFromDomain(
    String domain, String ticker) async {
  try {
    final domainParts = domain.split('.');
    final name = domainParts.last;

    if (domainParts.length <= 1 || domainParts.first.isEmpty || name.isEmpty) {
      return ParsedAddress(domain, ParseFrom.notParsed);
    }

    if (name.contains(topLevelDomain)) {
      final address = await fetchUnstoppableDomainAddress(domain, ticker);

      if (address?.isEmpty ?? true) {
        return ParsedAddress(domain, ParseFrom.notParsed);
      }

      return ParsedAddress(address, ParseFrom.unstoppableDomains);
    }

    final record = await OpenaliasRecord.fetchAddressAndName(
        OpenaliasRecord.formatDomainName(domain));

    if (record == null || record.address.contains(domain)) {
      return ParsedAddress(domain, ParseFrom.notParsed);
    }

    return ParsedAddress(record.address, ParseFrom.openAlias);
  } catch (e) {
    print(e.toString());
  }

  return ParsedAddress(domain, ParseFrom.notParsed);
}