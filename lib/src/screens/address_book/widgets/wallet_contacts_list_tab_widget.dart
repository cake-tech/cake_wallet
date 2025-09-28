import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WalletContactsListTabWidget extends StatelessWidget {
  const WalletContactsListTabWidget({required this.walletContacts, this.isEditable = false});

  final List<WalletContact> walletContacts;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final groupedContacts = <String, List<ContactBase>>{};
    for (var contact in walletContacts) {
      final baseName = _extractBaseName(contact.name);
      groupedContacts.putIfAbsent(baseName, () => []).add(contact);
    }

    return ListView.builder(
      itemCount: groupedContacts.length * 2,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          return StandardListSeparator(height: 0);
        } else {
          final groupIndex = index ~/ 2;
          final groupName = groupedContacts.keys.elementAt(groupIndex);
          final groupContacts = groupedContacts[groupName]!;

          if (groupContacts.length == 1) {
            final contact = groupContacts[0];
            return generateRaw(context, contact, isEditable);
          } else {
            final activeContact = groupContacts.firstWhere(
              (contact) => contact.name.contains('Active'),
              orElse: () => groupContacts[0],
            );

            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
              child: ExpansionTile(
                title: Text(
                  groupName,
                  style: Theme.of(context).textTheme.bodyMedium!,
                ),
                leading: _buildCurrencyIcon(activeContact),
                tilePadding: const EdgeInsets.only(left: 16, right: 16),
                childrenPadding: const EdgeInsets.only(left: 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                expandedAlignment: Alignment.topLeft,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                collapsedBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                children: groupContacts
                    .map((contact) => generateRaw(context, contact, isEditable))
                    .toList(),
              ),
            );
          }
        }
      },
    );
  }
}

String _extractBaseName(String name) {
  final bracketIndex = name.indexOf('(');
  return (bracketIndex != -1) ? name.substring(0, bracketIndex).trim() : name;
}

Widget generateRaw(BuildContext context, ContactBase contact, bool isEditable) {
  final currencyIcon = _buildCurrencyIcon(contact);

  return GestureDetector(
    onTap: () async {
      if (!isEditable) {
        Navigator.of(context).pop(contact);
        return;
      }

      final isCopied = await DialogService.showNameAndAddressDialog(context, contact);

      if (isCopied) {
        await Clipboard.setData(ClipboardData(text: contact.address));
        await showBar<void>(context, S.of(context).copied_to_clipboard);
      }
    },
    behavior: HitTestBehavior.opaque,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      margin: const EdgeInsets.only(top: 4, bottom: 4, left: 16, right: 16),
      padding: const EdgeInsets.only(top: 16, bottom: 16, right: 16, left: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          currencyIcon,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                contact.name,
                style: Theme.of(context).textTheme.bodyMedium!,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCurrencyIcon(ContactBase contact) {
  final image = contact.type.iconPath;
  return image != null
      ? Image.asset(image, height: 24, width: 24)
      : const SizedBox(height: 24, width: 24);
}

class DialogService {
  static Future<bool> showAlertDialog(BuildContext context) async {
    return await showPopUp<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithTwoActions(
                  alertTitle: S.of(context).address_remove_contact,
                  alertContent: S.of(context).address_remove_content,
                  rightButtonText: S.of(context).remove,
                  leftButtonText: S.of(context).cancel,
                  actionRightButton: () => Navigator.of(context).pop(true),
                  actionLeftButton: () => Navigator.of(context).pop(false));
            }) ??
        false;
  }

  static Future<bool> showNameAndAddressDialog(BuildContext context, ContactBase contact) async {
    return await showPopUp<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithTwoActions(
                  alertTitle: contact.name,
                  alertContent: contact.address,
                  alertContentTextWidget: AddressFormatter.buildSegmentedAddress(
                    address: contact.address,
                    textAlign: TextAlign.center,
                    walletType: cryptoCurrencyToWalletType(contact.type),
                    evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16,
                          decoration: TextDecoration.none,
                        ),
                  ),
                  rightButtonText: S.of(context).copy,
                  leftButtonText: S.of(context).cancel,
                  actionRightButton: () => Navigator.of(context).pop(true),
                  actionLeftButton: () => Navigator.of(context).pop(false));
            }) ??
        false;
  }
}
