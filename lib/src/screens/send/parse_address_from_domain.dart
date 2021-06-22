import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/unstoppable_domain_address.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

const topLevelDomain = 'crypto';

Future<String> parseAddressFromDomain(
    BuildContext context, String domain, String ticker) async {
  try {
    final name = domain.split('.').last;

    if (name.contains(topLevelDomain)) {
      final address = await fetchUnstoppableDomainAddress(domain, ticker);
      if (address.isNotEmpty) {
        showAddressAlert(
            context,
            S.of(context).address_detected,
            S.of(context).address_from_domain(domain));
        return address;
      }
    } else if (name.isNotEmpty) {
      final record = await OpenaliasRecord.fetchAddressAndName(
          OpenaliasRecord.formatDomainName(domain));
      if (record.name != null && record.name != domain) {
        showAddressAlert(
            context,
            S.of(context).openalias_alert_title,
            S.of(context).openalias_alert_content(domain));
        return record.address;
      }
    }
  } catch (e) {
    print(e.toString());
  }

  return domain;
}

void showAddressAlert(BuildContext context, String title, String content) async {
  await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {

        return AlertWithOneAction(
            alertTitle: title,
            alertContent: content,
            buttonText: S.of(context).ok,
            buttonAction: () => Navigator.of(context).pop());
      });
}