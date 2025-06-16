// import 'package:cake_wallet/entities/parsed_address.dart';
// import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
// import 'package:cake_wallet/utils/show_pop_up.dart';
// import 'package:flutter/material.dart';
// import 'package:cake_wallet/generated/i18n.dart';
// import 'choose_yat_address_alert.dart';
//
// Future<String> extractAddressFromParsed(
//     BuildContext context,
//     ParsedAddress parsedAddress) async {
//   var title = '';
//   var content = '';
//   var address = '';
//   var profileImageUrl = '';
//   var profileName = '';
//
//   switch (parsedAddress.addressSource) {
//     case AddressSource.unstoppableDomains:
//       title = S.of(context).address_detected;
//       content = S.of(context).address_from_domain(parsedAddress.handle);
//       address = parsedAddress.addresses.first;
//       break;
//     case AddressSource.ens:
//       title = S.of(context).address_detected;
//       content = S.of(context).extracted_address_content('${parsedAddress.handle} (ENS)');
//       address = parsedAddress.addresses.first;
//       break;
//     case AddressSource.openAlias:
//       title = S.of(context).address_detected;
//       content = S.of(context).extracted_address_content('${parsedAddress.handle} (OpenAlias)');
//       address = parsedAddress.addresses.first;
//       break;
//     case AddressSource.wellKnown:
//       title = S.of(context).address_detected;
//       content = S.of(context).extracted_address_content('${parsedAddress.handle} (Well-Known)');
//       address = parsedAddress.addresses.first;
//       break;
//     case AddressSource.fio:
//       title = S.of(context).address_detected;
//       content = S.of(context).extracted_address_content('${parsedAddress.handle} (FIO)');
//       address = parsedAddress.addresses.first;
//       break;
//     case AddressSource.twitter:
//       title = S.of(context).address_detected;
//       content = S.of(context).extracted_address_content('${parsedAddress.handle} (Twitter)');
//       address = parsedAddress.addresses.first;
//       profileImageUrl = parsedAddress.profileImageUrl;
//       profileName = parsedAddress.profileName;
//       break;
//     case AddressSource.mastodon:
//       title = S.of(context).address_detected;
//       content = S.of(context).extracted_address_content('${parsedAddress.handle} (Mastodon)');
//       address = parsedAddress.addresses.first;
//       profileImageUrl = parsedAddress.profileImageUrl;
//       profileName = parsedAddress.profileName;
//       break;
//     case AddressSource.nostr:
//       title = S.of(context).address_detected;
//       content = S.of(context).extracted_address_content('${parsedAddress.handle} (Nostr NIP-05)');
//       address = parsedAddress.addresses.first;
//       profileImageUrl = parsedAddress.profileImageUrl;
//       profileName = parsedAddress.profileName;
//       break;
//     case AddressSource.thorChain:
//       title = S.of(context).address_detected;
//       content = S.of(context).extracted_address_content('${parsedAddress.handle} (ThorChain)');
//       address = parsedAddress.addresses.first;
//       break;
//     case AddressSource.zanoAlias:
//       title = S.of(context).address_detected;
//       content = S.of(context).extracted_address_content('${parsedAddress.handle} (Zano Alias)');
//       address = parsedAddress.addresses.first;
//       break;
//     case AddressSource.bip353:
//       title = S.of(context).address_detected;
//       content = S.of(context).extracted_address_content('${parsedAddress.handle} (BIP-353)');
//       address = parsedAddress.addresses.first;
//       break;
//     case AddressSource.yatRecord:
//       if (parsedAddress.handle.isEmpty) {
//         title = S.of(context).yat_error;
//         content = S.of(context).yat_error_content;
//         address = parsedAddress.addresses.first;
//         break;
//       }
//
//       title = S.of(context).address_detected;
//       content = S.of(context).address_from_yat(parsedAddress.handle);
//
//       if (parsedAddress.addresses.length == 1) {
//         address = parsedAddress.addresses.first;
//         break;
//       }
//
//       content += S.of(context).choose_address;
//
//       address = await showPopUp<String?>(
//           context: context,
//           builder: (BuildContext context) {
//
//             return WillPopScope(
//               child: ChooseYatAddressAlert(
//                 alertTitle: title,
//                 alertContent: content,
//                 addresses: parsedAddress.addresses),
//               onWillPop: () async => false);
//           }) ?? '';
//
//       if (address.isEmpty) {
//         return parsedAddress.handle;
//       }
//
//       return address;
//     case AddressSource.contact:
//     case AddressSource.notParsed:
//       address = parsedAddress.addresses.first;
//       return address;
//   }
//
//   await showPopUp<void>(
//       context: context,
//       builder: (BuildContext context) {
//
//         return AlertWithOneAction(
//             alertTitle: title,
//             headerTitleText: profileName.isEmpty ? null : profileName,
//             headerImageProfileUrl: profileImageUrl.isEmpty ? null : profileImageUrl,
//             alertContent: content,
//             buttonText: S.of(context).ok,
//             buttonAction: () => Navigator.of(context).pop());
//       });
//
//   return address;
// }
