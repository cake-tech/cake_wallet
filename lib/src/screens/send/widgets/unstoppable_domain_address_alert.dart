import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

void unstoppableDomainAddressAlert(BuildContext context, String domain) async {
  await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {

        return AlertWithOneAction(
            alertTitle: S.of(context).address_detected,
            alertContent: S.of(context).address_from_domain(domain),
            buttonText: S.of(context).ok,
            buttonAction: () => Navigator.of(context).pop());
      });
}