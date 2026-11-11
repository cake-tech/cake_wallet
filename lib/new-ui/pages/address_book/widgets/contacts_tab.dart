import "dart:async";

import "package:cake_wallet/entities/contact_base.dart";
import "package:cake_wallet/entities/contact_record.dart";
import "package:cake_wallet/entities/wallet_list_order_types.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/dashboard/widgets/filter_list_widget.dart";
import "package:cake_wallet/src/screens/wallet_list/filtered_list.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/utils/show_bar.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/contact_list/contact_list_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_slidable/flutter_slidable.dart";

class ContactsTab extends StatefulWidget {
  const ContactsTab({required this.contactListViewModel, required this.tabController});

  final ContactListViewModel contactListViewModel;
  final TabController tabController;

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
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
      backgroundColor: Colors.transparent,
      body: FilteredList(
        list: contacts,
        updateFunction: widget.contactListViewModel.reorderAccordingToContactList,
        canReorder: widget.contactListViewModel.isEditable,
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 250),
        itemBuilder: (context, index) {
          final contact = contacts[index];
          final contactContent = generateContactRaw(context, contact, contacts.length == index + 1);
          return GestureDetector(
            key: Key(contact.name),
            onTap: () async {
              if (!widget.contactListViewModel.isEditable) {
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
            child: widget.contactListViewModel.isEditable
                ? Slidable(
                    key: Key("${contact.key}"),
                    endActionPane: _actionPane(context, contact),
                    child: contactContent,
                  )
                : contactContent,
          );
        },
      ),
      floatingActionButton: _isContactsTabActive && widget.contactListViewModel.isEditable
          ? filterButtonWidget(context, widget.contactListViewModel)
          : null,
    );
  }

  Widget generateContactRaw(BuildContext context, ContactRecord contact, bool isLast) {
    const l2NativeChainIcons = {
      CryptoCurrency.baseEth: "assets/new-ui/crypto_full_icons/base.svg",
      CryptoCurrency.arbEth: "assets/new-ui/crypto_full_icons/arbitrum.svg",
      CryptoCurrency.robEth: "assets/new-ui/crypto_full_icons/robinhood.svg",
    };
    final image = l2NativeChainIcons[contact.type] ?? contact.type.iconPath;
    final currencyIcon = (image != null && image.isNotEmpty)
        ? CakeImageWidget(imageUrl: image, height: 24, width: 24)
        : const SizedBox(height: 24, width: 24);
    return Column(
      children: [
        Container(
          key: Key(contact.name),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
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
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  contact.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ))
            ],
          ),
        ),
      ],
    );
  }

  ActionPane _actionPane(BuildContext context, ContactRecord contact) => ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(
            onPressed: (_) =>
                Navigator.of(context).pushNamed(Routes.addressBookAddContact, arguments: contact),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            icon: Icons.edit,
            label: S.of(context).edit,
          ),
          SlidableAction(
            onPressed: (_) async {
              final isDelete = await DialogService.showAlertDialog(context);

              if (isDelete) {
                await widget.contactListViewModel.delete(contact);
              }
            },
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            icon: CupertinoIcons.delete,
            label: S.of(context).delete,
          ),
        ],
      );

  Widget filterButtonWidget(BuildContext context, ContactListViewModel contactListViewModel) {
    final filterIcon = Image.asset(
      "assets/images/filter_icon.png",
      color: Theme.of(context).colorScheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 48),
      child: MergeSemantics(
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
                      onClose: (ascending, type) async {
                        contactListViewModel.setAscending(ascending);
                        await contactListViewModel.setOrderType(type);
                      },
                    ),
                  );
                },
                child: Semantics(
                  label: "Transaction Filter",
                  button: true,
                  enabled: true,
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: filterIcon,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DialogService {
  static Future<bool> showAlertDialog(BuildContext context) async =>
      await showPopUp<bool>(
        context: context,
        builder: (context) => AlertWithTwoActions(
          alertTitle: S.of(context).address_remove_contact,
          alertContent: S.of(context).address_remove_content,
          rightButtonText: S.of(context).remove,
          leftButtonText: S.of(context).cancel,
          actionRightButton: () => Navigator.of(context).pop(true),
          actionLeftButton: () => Navigator.of(context).pop(false),
        ),
      ) ??
      false;

  static Future<bool> showNameAndAddressDialog(BuildContext context, ContactBase contact) async =>
      await showPopUp<bool>(
        context: context,
        builder: (context) => AlertWithTwoActions(
          alertTitle: contact.name,
          alertContent: contact.address,
          alertContentTextWidget: AddressFormatter.buildSegmentedAddress(
            address: contact.address,
            textAlign: TextAlign.center,
            walletType: cryptoCurrencyOrTokenToWalletType(contact.type),
            evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
          ),
          rightButtonText: S.of(context).copy,
          leftButtonText: S.of(context).cancel,
          actionRightButton: () => Navigator.of(context).pop(true),
          actionLeftButton: () => Navigator.of(context).pop(false),
        ),
      ) ??
      false;
}
