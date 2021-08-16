import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

void showAddressAlert(BuildContext context, ParsedAddress parsedAddress) async {
  var title = '';
  var content = '';

  switch (parsedAddress.parseFrom) {
    case ParseFrom.unstoppableDomains:
      title = S.of(context).address_detected;
      content = S.of(context).address_from_domain(parsedAddress.name);
      break;
    case ParseFrom.openAlias:
      title = S.of(context).openalias_alert_title;
      content = S.of(context).openalias_alert_content(parsedAddress.name);
      break;
    case ParseFrom.notParsed:
      return;
  }

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