import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_list_widget.dart';
import 'package:cake_wallet/src/screens/wallet_list/filtered_list.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ContactListPage extends BasePage {
  ContactListPage(this.contactListViewModel, this.authService);

  final ContactListViewModel contactListViewModel;
  final AuthService authService;

  @override
  String get title => S.current.address_book;

  @override
  Widget? trailing(BuildContext context) {
    return MergeSemantics(
      child: Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).extension<ExchangePageTheme>()!.buttonBackgroundColor),
        child: Semantics(
          label: S.of(context).add_contact,
          button: true,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(
                Icons.add,
                color: Theme.of(context).appBarTheme.titleTextStyle!.color,
                size: 22.0,
              ),
              ButtonTheme(
                minWidth: 32.0,
                height: 32.0,
                child: TextButton(
                    // FIX-ME: Style
                    //shape: CircleBorder(),
                    onPressed: () async {
                      if (contactListViewModel.shouldRequireTOTP2FAForAddingContacts) {
                        authService.authenticateAction(
                          context,
                          route: Routes.addressBookAddContact,
                          conditionToDetermineIfToUse2FA:
                              contactListViewModel.shouldRequireTOTP2FAForAddingContacts,
                        );
                      } else {
                        await Navigator.of(context).pushNamed(Routes.addressBookAddContact);
                      }
                    },
                    child: Offstage()),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    double maxWalletListHeight = MediaQuery.of(context).size.height / 3;
    final walletContacts = contactListViewModel.walletContactsToShow;
    return Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            buildTitle(title: S.of(context).contact_list_wallets, topPadding: 0.0),
            StandardListSeparator(),
            generateGroupedWalletList(context, maxWalletListHeight, walletContacts),
            buildTitle(
                title: S.of(context).contact_list_contacts,
                trailingFilterButton:
                    contactListViewModel.isEditable ? trailingFilterButtonWidget(context) : null),
            Expanded(
              child: ContactListBody(contactListViewModel: contactListViewModel),
            ),
          ],
        ));
  }

  Widget generateGroupedWalletList(
      BuildContext context, double maxWalletListHeight, List<ContactBase> walletContacts) {
    final groupedContacts = <String, List<ContactBase>>{};

    for (var contact in walletContacts) {
      final baseName = _extractBaseName(contact.name);
      if (!groupedContacts.containsKey(baseName)) {
        groupedContacts[baseName] = [];
      }
      groupedContacts[baseName]!.add(contact);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxWalletListHeight),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: groupedContacts.length,
        itemBuilder: (context, index) {
          final groupName = groupedContacts.keys.elementAt(index);
          final groupContacts = groupedContacts[groupName]!;

          if (groupContacts.length == 1) {
            final contact = groupContacts[0];
            return generateRaw(context, contact);
          } else {
            return Theme(
              data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(groupName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                    )),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(left: 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                expandedAlignment: Alignment.topLeft,
                leading: _buildCurrencyIcon(groupContacts[0]),
                children: groupContacts.map((contact) => generateRaw(context, contact)).toList(),
              ),
            );
          }
        },
        separatorBuilder: (_, __) => StandardListSeparator(),
      ),
    );
  }

  String _extractBaseName(String name) {
    final bracketIndex = name.indexOf('(');
    if (bracketIndex != -1) {
      return name.substring(0, bracketIndex).trim();
    }
    return name;
  }

  Widget _buildCurrencyIcon(ContactBase contact) {
    final image = contact.type.iconPath;
    return image != null
        ? Image.asset(image, height: 24, width: 24)
        : const SizedBox(height: 24, width: 24);
  }

  Widget buildTitle(
      {required String title, Widget? trailingFilterButton, double topPadding = 20.0}) {
    return Container(
        padding: EdgeInsets.only(top: topPadding, bottom: 5.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: TextStyle(fontSize: 36)),
          trailingFilterButton ?? Container()
        ]));
  }

  Widget generateRaw(BuildContext context, ContactBase contact) {
    final currencyIcon = _buildCurrencyIcon(contact);

    return GestureDetector(
      onTap: () async {
        if (!contactListViewModel.isEditable) {
          Navigator.of(context).pop(contact);
          return;
        }

        final isCopied = await showNameAndAddressDialog(context, contact.name, contact.address);

        if (isCopied) {
          await Clipboard.setData(ClipboardData(text: contact.address));
          await showBar<void>(context, S.of(context).copied_to_clipboard);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(top: 16, bottom: 16, right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            currencyIcon,
            Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                contact.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<bool> showNameAndAddressDialog(BuildContext context, String name, String address) async {
    return await showPopUp<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithTwoActions(
                  alertTitle: name,
                  alertContent: address,
                  rightButtonText: S.of(context).copy,
                  leftButtonText: S.of(context).cancel,
                  actionRightButton: () => Navigator.of(context).pop(true),
                  actionLeftButton: () => Navigator.of(context).pop(false));
            }) ??
        false;
  }

  Widget trailingFilterButtonWidget(BuildContext context) {
    final filterIcon = Image.asset('assets/images/filter_icon.png',
        color: Theme.of(context).extension<FilterTheme>()!.iconColor);
    return MergeSemantics(
      child: SizedBox(
        height: 37,
        width: 37,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: Semantics(
            container: true,
            child: GestureDetector(
              onTap: () async {
                await showPopUp<void>(
                  context: context,
                  builder: (context) => FilterListWidget(
                    initalType: contactListViewModel.orderType,
                    initalAscending: contactListViewModel.ascending,
                    onClose: (bool ascending, FilterListOrderType type) async {
                      contactListViewModel.setAscending(ascending);
                      await contactListViewModel.setOrderType(type);
                    },
                  ),
                );
              },
              child: Semantics(
                label: 'Transaction Filter',
                button: true,
                enabled: true,
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).extension<FilterTheme>()!.buttonColor,
                  ),
                  child: filterIcon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ContactListBody extends StatefulWidget {
  ContactListBody({required this.contactListViewModel});

  final ContactListViewModel contactListViewModel;

  @override
  State<ContactListBody> createState() => _ContactListBodyState();
}

class _ContactListBodyState extends State<ContactListBody> {
  @override
  void dispose() {
    widget.contactListViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = widget.contactListViewModel.contactsToShow;
    return Container(
        child: FilteredList(
      list: contacts,
      updateFunction: widget.contactListViewModel.reorderAccordingToContactList,
      canReorder: widget.contactListViewModel.isEditable,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final contactContent = generateContactRaw(context, contact, contacts.length == index + 1);
        return GestureDetector(
          key: Key('${contact.name}'),
          onTap: () async {
            if (!widget.contactListViewModel.isEditable) {
              Navigator.of(context).pop(contact);
              return;
            }

            final isCopied = await showNameAndAddressDialog(context, contact.name, contact.address);

            if (isCopied) {
              await Clipboard.setData(ClipboardData(text: contact.address));
              await showBar<void>(context, S.of(context).copied_to_clipboard);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            child: widget.contactListViewModel.isEditable
                ? Slidable(
                    key: Key('${contact.key}'),
                    endActionPane: _actionPane(context, contact),
                    child: contactContent)
                : contactContent,
          ),
        );
      },
    ));
  }

  Widget generateContactRaw(BuildContext context, ContactRecord contact, bool isLast) {
    final image = contact.type.iconPath;
    final currencyIcon = image != null
        ? Image.asset(image, height: 24, width: 24)
        : const SizedBox(height: 24, width: 24);
    return Column(
      children: [
        StandardListSeparator(),
        Container(
          key: Key('${contact.name}'),
          padding: const EdgeInsets.only(top: 16, bottom: 16, right: 24),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  ),
                ),
              ))
            ],
          ),
        ),
        if (isLast) StandardListSeparator(),
      ],
    );
  }

  ActionPane _actionPane(BuildContext context, ContactRecord contact) => ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(
            onPressed: (_) async => await Navigator.of(context)
                .pushNamed(Routes.addressBookAddContact, arguments: contact),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: S.of(context).edit,
          ),
          SlidableAction(
            onPressed: (_) async {
              final isDelete = await showAlertDialog(context);

              if (isDelete) {
                await widget.contactListViewModel.delete(contact);
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: CupertinoIcons.delete,
            label: S.of(context).delete,
          ),
        ],
      );

  Future<bool> showAlertDialog(BuildContext context) async {
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

  Future<bool> showNameAndAddressDialog(BuildContext context, String name, String address) async {
    return await showPopUp<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithTwoActions(
                  alertTitle: name,
                  alertContent: address,
                  rightButtonText: S.of(context).copy,
                  leftButtonText: S.of(context).cancel,
                  actionRightButton: () => Navigator.of(context).pop(true),
                  actionLeftButton: () => Navigator.of(context).pop(false));
            }) ??
        false;
  }
}
