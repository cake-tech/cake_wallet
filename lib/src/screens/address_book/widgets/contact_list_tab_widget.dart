import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_list_widget.dart';
import 'package:cake_wallet/src/screens/wallet_list/filtered_list.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/contact_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/search_bar_widget.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';

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
    final isEditable = widget.contactListViewModel.isEditable;
    final contacts = widget.contactListViewModel.contacts;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        child: Column(
          children: [
            SearchBarWidget(
                key: ValueKey('contact_search_bar_key'), searchController: TextEditingController()),
            const SizedBox(height: 8),
            FilteredList(
              list: contacts,
              updateFunction: widget.contactListViewModel.reorderAccordingToContactList,
              canReorder: isEditable,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return _buildContactTile(
                    context: context,
                    contact: contact,
                    contactListViewModel: widget.contactListViewModel);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: _isContactsTabActive && isEditable
          ? filterButtonWidget(context, widget.contactListViewModel)
          : null,
    );
  }

  final double _iconSize   = 24;
  final double _iconOffset = 16;

  Widget _buildSourceIcons(ContactRecord contact) {
    final sources = <AddressSource>{};

    for (final handleKey in contact.parsedBlocks.keys) {
      final srcLabel = handleKey.split('-').first;
      sources.add(AddressSourceNameParser.fromLabel(srcLabel));
    }

    if (sources.isEmpty) {
      return const SizedBox.shrink();
    }

    final srcList = sources.toList();
    return SizedBox(
      width : _iconSize + _iconOffset * (srcList.length - 1),
      height: _iconSize,
      child : Stack(
        children: [
          for (var i = 0; i < srcList.length; ++i)
            Positioned(
              left: i * _iconOffset,
              child: CircleAvatar(
                radius: _iconSize / 2,
                backgroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                child: CircleAvatar(
                  radius: (_iconSize / 2) - 1,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  child: ImageUtil.getImageFromPath(
                    imagePath: srcList[i].iconPath,
                    height   : _iconSize - 6,
                    width    : _iconSize - 6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

// … inside _buildContactTile()
  Widget _buildContactTile({
    required BuildContext context,
    required ContactRecord contact,
    required ContactListViewModel contactListViewModel,
  }) {
    final selectedCurrency = contactListViewModel.selectedCurrency;

    return ListTile(
      key: ValueKey(contact.key),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
      tileColor: Theme.of(context).colorScheme.surfaceContainer,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image(
          image : contact.avatarProvider,
          width : 24,
          height: 24,
          fit   : BoxFit.cover,
        ),
      ),

      // NEW trailing overlay
      trailing: _buildSourceIcons(contact),

      title: Text(contact.name, style: Theme.of(context).textTheme.bodyMedium),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      onTap: () => selectedCurrency != null
          ? _openContactRefreshBottomSheet(
        context      : context,
        wallet       : contactListViewModel.wallet,
        initialRoute : Routes.contactRefreshPage,
        initialArgs  : [contact, selectedCurrency],
      )
          : _openBottomSheet(
        context      : context,
        wallet       : contactListViewModel.wallet,
        initialRoute : Routes.contactPage,
        initialArgs  : contact,
      ),
    );
  }

  Widget filterButtonWidget(BuildContext context, ContactListViewModel contactListViewModel) {
    final filterIcon = Image.asset(
      'assets/images/filter_icon.png',
      color: Theme.of(context).colorScheme.onSurface,
    );
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
                    color: Theme.of(context).colorScheme.surfaceContainer,
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

  Future<void> _openBottomSheet(
      {required BuildContext context,
      required WalletBase wallet,
      String? initialRoute,
      Object? initialArgs}) async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext bottomSheetContext) {
          return AddressBookBottomSheet(
              initialRoute: initialRoute,
              initialArgs: initialArgs);
        });
  }

  Future<void> _openContactRefreshBottomSheet({
    required BuildContext context,
    required WalletBase wallet,
    String? initialRoute,
    Object? initialArgs,
  }) async {
    final contact = await showModalBottomSheet<(ContactRecord,String)>(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return AddressBookBottomSheet(
          initialRoute   : initialRoute,
          initialArgs    : initialArgs,
        );
      },
    );
    if (contact?.$1 != null && context.mounted) {
      Navigator.of(context).pop(contact);
    }
  }
}
