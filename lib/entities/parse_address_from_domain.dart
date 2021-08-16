import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/entities/unstoppable_domain_address.dart';

const unstoppableDomains = [
   'crypto',
   'zil',
   'x',
   'coin',
   'wallet',
   'bitcoin',
   '888',
   'nft',
   'dao',
   'blockchain'];

Future<ParsedAddress> parseAddressFromDomain(
    String domain, String ticker) async {
  try {
    final formattedName = OpenaliasRecord.formatDomainName(domain);
    final domainParts = formattedName.split('.');
    final name = domainParts.last;

    if (domainParts.length <= 1 || domainParts.first.isEmpty || name.isEmpty) {
      return ParsedAddress(address: domain);
    }

    if (unstoppableDomains.any((domain) => name.contains(domain))) {
      final address =
        await fetchUnstoppableDomainAddress(domain, ticker);

      if (address?.isEmpty ?? true) {
        return ParsedAddress(address: domain);
      }

      return ParsedAddress(
          address: address,
          name: domain,
          parseFrom: ParseFrom.unstoppableDomains);
    }

    final record = await OpenaliasRecord.fetchAddressAndName(formattedName);

    if (record == null || record.address.contains(formattedName)) {
      return ParsedAddress(address: domain);
    }

    return ParsedAddress(
        address: record.address,
        name: record.name,
        parseFrom: ParseFrom.openAlias);
  } catch (e) {
    print(e.toString());
  }

  return ParsedAddress(address: domain);
}