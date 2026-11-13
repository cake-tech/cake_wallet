import "dart:async";

import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/contact_base.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/page_open_listener.dart";
import "package:cake_wallet/new-ui/pages/address_book/other_wallets_page.dart";
import "package:cake_wallet/new-ui/pages/address_book/widgets/contacts_tab.dart";
import "package:cake_wallet/new-ui/pages/address_book/widgets/grouped_wallet_contacts_tab.dart";
import "package:cake_wallet/new-ui/pages/address_book/widgets/legacy_wallet_contacts_tab.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_state.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/pill_tab_switcher.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/screens/dashboard/widgets/filter_list_widget.dart";
import "package:cake_wallet/src/widgets/gradient_background.dart";
import "package:cake_wallet/utils/show_bar.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/contact_list/contact_list_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class ContactListPage extends BasePage implements PageOpenListener {
  ContactListPage(this.contactListViewModel, this.authService,
      {this.currency, this.showAddButton = false});

  final ContactListViewModel contactListViewModel;
  final AuthService authService;
  final bool showAddButton;

  final CryptoCurrency? currency;

  final ValueNotifier<int> selectedTab = ValueNotifier(ContactPageBody.contactsTabIndex);

  final ValueNotifier<int> _pageOpens = ValueNotifier(0);

  @override
  bool get gradientBackground => true;

  @override
  String get title => S.current.address_book;

  @override
  PreferredSizeWidget appBar(BuildContext context) => AppBar(
        automaticallyImplyLeading: false,
        leading: leading(context),
        title: middle(context),
        centerTitle: false,
        titleSpacing: leading(context) == null ? 18 : 8,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18, top: 12),
            child: trailing(context),
          ),
        ],
        backgroundColor: pageBackgroundColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      );

  @override
  Widget? trailing(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<int>(
      valueListenable: selectedTab,
      builder: (context, tab, _) {
        final showFilter =
            tab == ContactPageBody.contactsTabIndex && contactListViewModel.isEditable;

        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            if (showFilter)
              ModernButton.svg(
                key: const ValueKey("contact_list_page_filter_button_key"),
                iconColor: colorScheme.primary,
                size: 30,
                iconSize: 20,
                svgPath: "assets/new-ui/filter_options.svg",
                semanticLabel: S.of(context).filters,
                onPressed: () => _showFilter(context),
              ),
            if (showAddButton)
              ModernButton.svg(
                key: const ValueKey("contact_list_page_add_contact_button_key"),
                iconColor: colorScheme.primary,
                size: 30,
                iconSize: 20,
                svgPath: "assets/new-ui/plus.svg",
                semanticLabel: S.of(context).add_contact,
                onPressed: () => _onAddContact(context),
              ),
          ],
        );
      },
    );
  }

  Future<void> _onAddContact(BuildContext context) async {
    if (contactListViewModel.shouldRequireTOTP2FAForAddingContacts) {
      authService.authenticateAction(
        context,
        route: Routes.addressBookAddContact,
        conditionToDetermineIfToUse2FA: contactListViewModel.shouldRequireTOTP2FAForAddingContacts,
      );
    } else {
      await Navigator.of(context).pushNamed(Routes.addressBookAddContact);
    }
  }

  Future<void> _showFilter(BuildContext context) => showPopUp<void>(
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

  @override
  void onPageOpen() => _pageOpens.value++;

  @override
  Widget body(BuildContext context) => ContactPageBody(
        contactListViewModel: contactListViewModel,
        selectedTab: selectedTab,
        currency: currency,
        pageOpens: _pageOpens,
      );
}

class ContactPageBody extends StatefulWidget {
  const ContactPageBody({
    required this.contactListViewModel,
    required this.selectedTab,
    required this.pageOpens,
    this.currency,
  });

  static const contactsTabIndex = 0;
  static const walletsTabIndex = 1;

  final ContactListViewModel contactListViewModel;
  final ValueNotifier<int> selectedTab;
  final ValueListenable<int> pageOpens;
  final CryptoCurrency? currency;

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
    _tabController.addListener(_onTabChanged);
    contactListViewModel = widget.contactListViewModel;
  }

  void _onTabChanged() {
    if (!mounted) return;
    widget.selectedTab.value = _tabController.index;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    contactListViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<WalletContactsCubit>(
        create: (_) => getIt.get<WalletContactsCubit>(param1: widget.currency)..load(),
        child: _RefreshOnPageOpen(
          pageOpens: widget.pageOpens,
          child: GradientBackground(
            scaffold: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: PillTabSwitcher(
                    tabs: [
                      S.of(context).contact_list_contacts,
                      S.of(context).wallets,
                    ],
                    selectedTab: _tabController.index,
                    onTabChange: _tabController.animateTo,
                    expand: true,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ContactsTab(
                        contactListViewModel: widget.contactListViewModel,
                        tabController: _tabController,
                      ),
                      BlocBuilder<WalletContactsCubit, WalletContactsState>(
                        builder: _buildWalletContacts,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildWalletContacts(BuildContext context, WalletContactsState state) =>
      widget.contactListViewModel.isEditable
          ? GroupedWalletContactsTab(
              state: state,
              onOtherWalletsTap: () => OtherWalletsPage.show(
                context,
                onContactTap: (contact) => _onWalletContactTap(context, contact),
              ),
            )
          : LegacyWalletContactsTab(
              state: state,
              onContactTap: (contact) => _onWalletContactTap(context, contact),
            );

  Future<void> _onWalletContactTap(BuildContext context, ContactBase contact) async {
    if (!widget.contactListViewModel.isEditable) {
      Navigator.of(context).pop(contact);
      return;
    }

    final isCopied = await DialogService.showNameAndAddressDialog(context, contact);

    if (isCopied) {
      await Clipboard.setData(ClipboardData(text: contact.address));
      await showBar<void>(context, S.of(context).copied_to_clipboard);
    }
  }
}

class _RefreshOnPageOpen extends StatefulWidget {
  const _RefreshOnPageOpen({required this.pageOpens, required this.child});

  final ValueListenable<int> pageOpens;
  final Widget child;

  @override
  State<_RefreshOnPageOpen> createState() => _RefreshOnPageOpenState();
}

class _RefreshOnPageOpenState extends State<_RefreshOnPageOpen> {
  @override
  void initState() {
    super.initState();
    widget.pageOpens.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _RefreshOnPageOpen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageOpens != widget.pageOpens) {
      oldWidget.pageOpens.removeListener(_refresh);
      widget.pageOpens.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) unawaited(context.read<WalletContactsCubit>().refresh());
  }

  @override
  void dispose() {
    widget.pageOpens.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
