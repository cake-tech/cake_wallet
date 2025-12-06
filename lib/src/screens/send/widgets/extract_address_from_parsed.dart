import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'choose_yat_address_alert.dart';

Future<String> extractAddressFromParsed(
    BuildContext context,
    ParsedAddress parsedAddress) async {
  if (!context.mounted) return parsedAddress.addresses.first;

  var title = '';
  var content = '';
  var address = '';
  var profileImageUrl = '';
  var profileName = '';

  switch (parsedAddress.parseFrom) {
    case ParseFrom.unstoppableDomains:
      title = S.of(context).address_detected;
      content = S.of(context).address_from_domain(parsedAddress.name);
      address = parsedAddress.addresses.first;
      break;
    case ParseFrom.ens:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (ENS)');
      address = parsedAddress.addresses.first;
      break;
    case ParseFrom.openAlias:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (OpenAlias)');
      address = parsedAddress.addresses.first;
      break;
    case ParseFrom.wellKnown:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (Well-Known)');
      address = parsedAddress.addresses.first;
      break;
    case ParseFrom.fio:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (FIO)');
      address = parsedAddress.addresses.first;
      break;
    case ParseFrom.twitter:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (Twitter)');
      address = parsedAddress.addresses.first;
      profileImageUrl = parsedAddress.profileImageUrl;
      profileName = parsedAddress.profileName;
      break;
    case ParseFrom.mastodon:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (Mastodon)');
      address = parsedAddress.addresses.first;
      profileImageUrl = parsedAddress.profileImageUrl;
      profileName = parsedAddress.profileName;
      break;
    case ParseFrom.nostr:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (Nostr NIP-05)');
      address = parsedAddress.addresses.first;
      profileImageUrl = parsedAddress.profileImageUrl;
      profileName = parsedAddress.profileName;
      break;
    case ParseFrom.thorChain:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (ThorChain)');
      address = parsedAddress.addresses.first;
      break;
    case ParseFrom.zanoAlias:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (Zano Alias)');
      address = parsedAddress.addresses.first;
      break;
    case ParseFrom.bip353:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (BIP-353)');
      address = parsedAddress.addresses.first;
      break;
    case ParseFrom.lnurlpay:
      title = S.of(context).address_detected;
      content = S.of(context).extracted_address_content('${parsedAddress.name} (Lightning)');
      address = parsedAddress.addresses.first;
      break;
    case ParseFrom.yatRecord:
      if (parsedAddress.name.isEmpty) {
        title = S.of(context).yat_error;
        content = S.of(context).yat_error_content;
        address = parsedAddress.addresses.first;
        break;
      }

      title = S.of(context).address_detected;
      content = S.of(context).address_from_yat(parsedAddress.name);

      if (parsedAddress.addresses.length == 1) {
        address = parsedAddress.addresses.first;
        break;
      }

      content += S.of(context).choose_address;

      address = await showPopUp<String?>(
            context: context,
            builder: (context) => PopScope(
              child: ChooseYatAddressAlert(
                alertTitle: title,
                alertContent: content,
                addresses: parsedAddress.addresses,
              ),
              canPop: false,
            ),
          ) ??
          '';

      if (address.isEmpty) {
        return parsedAddress.name;
      }

      return address;
    case ParseFrom.contact:
    case ParseFrom.notParsed:
      return parsedAddress.addresses.first;
  }

  await showPopUp<void>(
    context: context,
    builder: (context) => AlertWithOneAction(
      alertTitle: title,
      headerTitleText: profileName.isEmpty ? null : profileName,
      headerImageProfileUrl: profileImageUrl.isEmpty ? null : profileImageUrl,
      alertContent: content,
      buttonText: S.of(context).ok,
      buttonAction: () => Navigator.of(context).pop(),
    ),
  );

  return address;
}
