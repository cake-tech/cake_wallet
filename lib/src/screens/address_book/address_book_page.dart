import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/address_resolver/address_resolver_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/contact_list_tab_widget.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/wallet_contacts_list_tab_widget.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/contact_bottom_sheet_widget.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:flutter/material.dart';

class AddressBookPage extends BasePage {
  AddressBookPage(this.contactListViewModel, this.authService);

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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Semantics(
          label: S.of(context).add_contact,
          button: true,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSurface,
                size: 22.0,
              ),
              ButtonTheme(
                minWidth: 32.0,
                height: 32.0,
                child: TextButton(
                  // FIX-ME: Style
                  //shape: CircleBorder(),
                  onPressed: () async {
                    await _showAddressBookBottomSheet(
                        context: context, contactListViewModel: contactListViewModel);
                  },
                  child: Offstage(),
                ),
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
      padding: const EdgeInsets.only(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tabController,
                splashFactory: NoSplash.splashFactory,
                indicatorSize: TabBarIndicatorSize.label,
                isScrollable: true,
                labelStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                unselectedLabelStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorPadding: EdgeInsets.zero,
                labelPadding: EdgeInsets.only(right: 24),
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                padding: EdgeInsets.zero,
                tabs: [
                  Tab(text: S.of(context).wallets),
                  Tab(text: S.of(context).contact_list_contacts),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                WalletContactsListTabWidget(
                  walletContacts: contactListViewModel.walletContactsToShow,
                  isEditable: contactListViewModel.isEditable,
                ),
                ContactListBody(
                  contactListViewModel: widget.contactListViewModel,
                  tabController: _tabController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddressBookBottomSheet(
    {required BuildContext context,
    required ContactListViewModel contactListViewModel,
    String? initialRoute,
    Object? initialArgs}) async {
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bottomSheetContext) {
        return AddressBookBottomSheet(
          initialRoute: initialRoute,
          initialArgs: initialArgs,
        );
      });
}
