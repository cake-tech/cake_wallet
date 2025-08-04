import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/address_resolver/parsed_address.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_list_widget.dart';
import 'package:cake_wallet/src/screens/wallet_list/filtered_list.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/contact_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/search_bar_widget.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class ContactListBody extends StatefulWidget {
  const ContactListBody({
    required this.contactListViewModel,
    required this.tabController,
    super.key,
  });

  final ContactListViewModel contactListViewModel;
  final TabController tabController;

  @override
  State<ContactListBody> createState() => _ContactListBodyState();
}

class _ContactListBodyState extends State<ContactListBody> {
  final _searchCtrl = TextEditingController();

  late final VoidCallback _tabListener;
  late final VoidCallback _searchListener;

  bool get _contactsTab => widget.tabController.index == 1;

  ContactListViewModel get _viewModel => widget.contactListViewModel;

  @override
  void initState() {
    super.initState();

    _tabListener = () {
      if (!mounted) return;
      setState(() {});
    };
    widget.tabController.addListener(_tabListener);

    _searchListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _searchCtrl.addListener(_searchListener);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_tabListener);
    _searchCtrl.removeListener(_searchListener);
    _searchCtrl.dispose();

    if (_viewModel.settingsStore.contactListOrder ==
        FilterListOrderType.Custom) {
      _viewModel.saveCustomOrder();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final editable = _viewModel.isEditable && query.isEmpty;


    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: _contactsTab && editable ? _filterBtn(context) : null,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        child: Column(
          children: [
            SearchBarWidget(key: const ValueKey('contact_search'), searchController: _searchCtrl),
            const SizedBox(height: 8),
            Expanded(
              child: Observer(
                builder: (_) {
                  final list = ObservableList<ContactRecord>.of(
                    _viewModel.contactsToShow
                        .where((c) => c.name.toLowerCase().contains(query)),
                  );

                  return FilteredList(
                    list: list,
                    canReorder: editable,
                    updateFunction: _viewModel.reorderAccordingToContactList,
                    itemBuilder: (context, i) => _item(context, list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext ctx, ContactRecord c) {
    final cur = _viewModel.selectedCurrency;
    final bg = Theme.of(ctx).colorScheme.surfaceContainer;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        key: ValueKey(c.key),
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image(image: c.avatarProvider, width: 24, height: 24, fit: BoxFit.cover),
        ),
        trailing: _icons(ctx, c),
        title: Text(c.name, style: Theme.of(ctx).textTheme.bodyMedium),
        onTap: () => _openSheet(
          ctx,
          cur != null ? Routes.contactRefreshPage : Routes.contactPage,
          cur != null ? [c, cur] : c,
        ),
      ),
    );
  }

  Widget _icons(BuildContext ctx, ContactRecord c) {
    const size = 24.0, gap = 16.0;
    final set = <AddressSource>{
      for (final k in c.parsedBlocks.keys) AddressSourceNameParser.fromLabel(k.split('-').first)
    };
    if (set.isEmpty) return const SizedBox.shrink();

    final lst = set.toList(growable: false);
    return SizedBox(
      width: size + gap * (lst.length - 1),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < lst.length; ++i)
            Positioned(
              left: i * gap,
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: Theme.of(ctx).colorScheme.onSecondaryContainer,
                child: CircleAvatar(
                  radius: (size / 2) - 1,
                  backgroundColor: Theme.of(ctx).colorScheme.outlineVariant,
                  child: ImageUtil.getImageFromPath(
                    imagePath: lst[i].iconPath,
                    height: size - 6,
                    width: size - 6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterBtn(BuildContext ctx) => SizedBox(
        height: 58,
        width: 58,
        child: GestureDetector(
          onTap: () async {
            await showPopUp<void>(
              context: ctx,
              builder: (_) => FilterListWidget(
                initalType: _viewModel.orderType,
                initalAscending: _viewModel.ascending,
                onClose: (asc, type) async {
                  _viewModel.setAscending(asc);
                  await _viewModel.setOrderType(type);
                },
                showGroupByType: false,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(ctx).colorScheme.surfaceContainer,
            ),
            child: Image.asset(
              'assets/images/filter_icon.png',
              color: Theme.of(ctx).colorScheme.onSurface,
            ),
          ),
        ),
      );

  Future<void> _openSheet(BuildContext ctx, String route, Object args) async {
    final res = await showModalBottomSheet<(ContactRecord, String)>(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => AddressBookBottomSheet(initialRoute: route, initialArgs: args),
    );
    if (res?.$1 != null && ctx.mounted) Navigator.of(ctx).pop(res);
  }
}
