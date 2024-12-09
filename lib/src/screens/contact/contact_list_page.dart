import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/contact.dart';
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
  Widget body(BuildContext context) => ContactPageBody(contactListViewModel: contactListViewModel);
}

class ContactPageBody extends StatefulWidget {
  const ContactPageBody({required this.contactListViewModel});

  final ContactListViewModel contactListViewModel;

  @override
  State<ContactPageBody> createState() => _ContactPageBodyState();
}

class _ContactPageBodyState extends State<ContactPageBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ContactListViewModel contactListViewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    contactListViewModel = widget.contactListViewModel;
  }

  @override
  void dispose() {
    _tabController.dispose();
    contactListViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              splashFactory: NoSplash.splashFactory,
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: true,
              labelStyle: TextStyle(
                fontSize: 18,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).appBarTheme.titleTextStyle!.color,
              ),
              unselectedLabelStyle: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).appBarTheme.titleTextStyle!.color?.withOpacity(0.5)),
              labelColor: Theme.of(context).appBarTheme.titleTextStyle!.color,
              indicatorColor: Theme.of(context).appBarTheme.titleTextStyle!.color,
              indicatorPadding: EdgeInsets.zero,
              labelPadding: EdgeInsets.only(right: 24),
              tabAlignment: TabAlignment.center,
              dividerColor: Colors.transparent,
              padding: EdgeInsets.zero,
              tabs: [
                Tab(text: S.of(context).wallets),
                Tab(text: S.of(context).contact_list_contacts),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWalletContacts(context),
                ContactListBody(
                    contactListViewModel: widget.contactListViewModel,
                    tabController: _tabController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletContacts(BuildContext context) {
    final walletContacts = widget.contactListViewModel.walletContactsToShow;

    final groupedContacts = <String, List<ContactBase>>{};
    for (var contact in walletContacts) {
      final baseName = _extractBaseName(contact.name);
      groupedContacts.putIfAbsent(baseName, () => []).add(contact);
    }

    return ListView.builder(
      itemCount: groupedContacts.length * 2,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          return StandardListSeparator();
        } else {
          final groupIndex = index ~/ 2;
          final groupName = groupedContacts.keys.elementAt(groupIndex);
          final groupContacts = groupedContacts[groupName]!;

          if (groupContacts.length == 1) {
            final contact = groupContacts[0];
            return generateRaw(context, contact);
          } else {
            final activeContact = groupContacts.firstWhere(
              (contact) => contact.name.contains('Active'),
              orElse: () => groupContacts[0],
            );

            return ExpansionTile(
              title: Text(
                groupName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
              leading: _buildCurrencyIcon(activeContact),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(left: 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              expandedAlignment: Alignment.topLeft,
              children: groupContacts.map((contact) => generateRaw(context, contact)).toList(),
            );
          }
        }
      },
    );
  }

  String _extractBaseName(String name) {
    final bracketIndex = name.indexOf('(');
    return (bracketIndex != -1) ? name.substring(0, bracketIndex).trim() : name;
  }

  Widget generateRaw(BuildContext context, ContactBase contact) {
    final currencyIcon = _buildCurrencyIcon(contact);

    return GestureDetector(
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
      child: Container(
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

class ContactListBody extends StatefulWidget {
  ContactListBody({required this.contactListViewModel, required this.tabController});

  final ContactListViewModel contactListViewModel;
  final TabController tabController;

  @override
  State<ContactListBody> createState() => _ContactListBodyState();
}

class _ContactListBodyState extends State<ContactListBody> {
  bool _isContactsTabActive = false;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    setState(() {
      _isContactsTabActive = widget.tabController.index == 1;
    });
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    if (widget.contactListViewModel.settingsStore.contactListOrder == FilterListOrderType.Custom) {
      widget.contactListViewModel.saveCustomOrder();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = widget.contactListViewModel.isEditable
        ? widget.contactListViewModel.contacts
        : widget.contactListViewModel.contactsToShow;
    return Scaffold(
      body: Container(
        child: FilteredList(
          list: contacts,
          updateFunction: widget.contactListViewModel.reorderAccordingToContactList,
          canReorder: widget.contactListViewModel.isEditable,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            final contactContent =
                generateContactRaw(context, contact, contacts.length == index + 1);
            return GestureDetector(
              key: Key('${contact.name}'),
              onTap: () async {
                if (!widget.contactListViewModel.isEditable) {
                  Navigator.of(context).pop(contact);
                  return;
                }

                final isCopied =
                    await showNameAndAddressDialog(context, contact.name, contact.address);

                if (isCopied) {
                  await Clipboard.setData(ClipboardData(text: contact.address));
                  await showBar<void>(context, S.of(context).copied_to_clipboard);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: widget.contactListViewModel.isEditable
                  ? Slidable(
                      key: Key('${contact.key}'),
                      endActionPane: _actionPane(context, contact),
                      child: contactContent)
                  : contactContent,
            );
          },
        ),
      ),
      floatingActionButton: _isContactsTabActive && widget.contactListViewModel.isEditable
          ? filterButtonWidget(context, widget.contactListViewModel)
          : null,
    );
  }

  Widget generateContactRaw(BuildContext context, ContactRecord contact, bool isLast) {
    final image = contact.type.iconPath;
    final currencyIcon = image != null
        ? Image.asset(image, height: 24, width: 24)
        : const SizedBox(height: 24, width: 24);
    return Column(
      children: [
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
        StandardListSeparator()
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

  Widget filterButtonWidget(BuildContext context, ContactListViewModel contactListViewModel) {
    final filterIcon = Image.asset('assets/images/filter_icon.png',
        color: Theme.of(context).appBarTheme.titleTextStyle!.color);
    return MergeSemantics(
      child: SizedBox(
        height: 58,
        width: 58,
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
                    color: Theme.of(context).extension<ExchangePageTheme>()!.buttonBackgroundColor,
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
