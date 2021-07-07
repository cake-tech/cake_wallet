import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/unstoppable_domain_address.dart';
import 'package:cake_wallet/src/screens/send/widgets/parse_address_from_domain_alert.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

const topLevelDomain = 'crypto';

Future<String> parseAddressFromDomain(
    BuildContext context, String domain, String ticker) async {
  try {
    final domainParts = domain.split('.');
    final name = domainParts.last;

    if (domainParts.length <= 1 || domainParts.first.isEmpty || name.isEmpty) {
      return domain;
    }

    if (name.contains(topLevelDomain)) {
      final address = await fetchUnstoppableDomainAddress(domain, ticker);

      if (address?.isEmpty ?? true) {
        return domain;
      }

      showAddressAlert(
          context,
          S.of(context).address_detected,
          S.of(context).address_from_domain(domain));

      return address;
    }

    final record = await OpenaliasRecord.fetchAddressAndName(
        OpenaliasRecord.formatDomainName(domain));

    if (record == null || record.address.contains(domain)) {
      return domain;
    }

    showAddressAlert(
        context,
        S.of(context).openalias_alert_title,
        S.of(context).openalias_alert_content(domain));

    return record.address;
  } catch (e) {
    print(e.toString());
  }

  return domain;
}