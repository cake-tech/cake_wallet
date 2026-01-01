import 'dart:ui';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/new-ui/long_press_popup.dart';
import 'package:cake_wallet/new-ui/widgets/addresses_page/address_label_input.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart';
import 'package:cake_wallet/new-ui/widgets/long_press_menu.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';

import 'package:cake_wallet/utils/list_item.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class NewAddressesPage extends StatefulWidget {
  const NewAddressesPage(
      {super.key,
      required this.addressListViewModel,
      required this.dashboardViewModel,
      required this.showHidden});

  final WalletAddressListViewModel addressListViewModel;
  final DashboardViewModel dashboardViewModel;
  final bool showHidden;

  @override
  State<NewAddressesPage> createState() => _NewAddressesPageState();
}

class _NewAddressesPageState extends State<NewAddressesPage> {
  List<ListItem> getItems(List<ListItem> list) {
    return list.where((element) {
      if (element is WalletAddressListItem) {
        if (!element.isHidden && !widget.showHidden) return true;
        if (element.isHidden && widget.showHidden) return true;
        return false;
      }
      return false;
    }).toList();
  }

  List<ListItem> items = [];

  late final TextEditingController _searchController;

  void updateItems() {
    setState(() {
      items = getItems(widget.addressListViewModel.forceRecomputeItems);
    });
  }

  @override
  void initState() {
    super.initState();

    items = getItems(widget.addressListViewModel.items);
    _searchController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });
    ;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = items.where((item) {
      if (item is! WalletAddressListItem) return false;
      if (_searchController.text.isEmpty) return true;
      if (item.name == null || item.name!.isEmpty) {
        return (item.address.contains(_searchController.text.toLowerCase()));
      }
      return (item.name ?? '').toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        spacing: 12.0,
        children: [
          ModalTopBar(
              title: widget.showHidden ? "Hidden addresses" : "Addresses",
              leadingIcon: Icon(Icons.arrow_back),
              onLeadingPressed: Navigator.of(context).pop,
              onTrailingPressed: () {}),
          Expanded(
            child: Stack(
              children: [
                CustomScrollView(
                  controller: ModalScrollController.of(context),
                  slivers: [
                    if (!widget.showHidden)
                      SliverToBoxAdapter(
                        child: Column(
                          spacing: 16,
                          children: [
                            if(widget.dashboardViewModel.type == WalletType.monero || widget.dashboardViewModel.type == WalletType.wownero)
                              AccountPreviewHeader(dashboardViewModel: widget.dashboardViewModel),
                            Text("Long press to edit address", style: TextStyle(
                              fontSize:10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant
                            ),),
                            ShowHiddenButton()
                          ],
                        ),
                      ),
                    SliverList.separated(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        if (item is WalletAddressListItem) {
                          return Observer(
                            builder: (_) => AddressRow(
                              selected: item.address == widget.addressListViewModel.address.address,
                              first: widget.showHidden && index == 0,
                              last: index == filteredItems.length - 1,
                              item: item,
                              onSelect: () {
                                widget.addressListViewModel.setAddress(item);
                              },
                              onLabelChanged: updateItems,
                              onAddressHidden: () async {
                                await widget.addressListViewModel.toggleHideAddress(item);
                                updateItems();
                              },
                              walletType: widget.addressListViewModel.type,
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                      separatorBuilder: (_, __) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: 1,
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        ),
                      ),
                    ),
                  ],
                ),
                AddressSearchBox(controller: _searchController),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class AddressSearchBox extends StatelessWidget {
  const AddressSearchBox({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 18.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh.withAlpha(128),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest, width: 1),
                  borderRadius: BorderRadius.circular(99999)),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Icon(Icons.search),
                  filled: false,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(99999),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(99999),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountPreviewHeader extends StatelessWidget {
  AccountPreviewHeader({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;


  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 10,
              children: [
                Observer(
                  builder: (_) => BalanceCard(
                      borderRadius: 5,
                      width: 50,
                      design: dashboardViewModel.cardDesigns.isNotEmpty
                          ? dashboardViewModel.cardDesigns.first
                          : CardDesign.genericDefault),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      monero?.getCurrentAccount(dashboardViewModel.wallet).label ??
                      wownero?.getCurrentAccount(dashboardViewModel.wallet).label ?? "",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                    ),
                    Text(
                      dashboardViewModel.wallet.name,
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    )
                  ],
                ),
              ],
            ),
            Row(
              spacing: 12,
              children: [
                Container(
                  width: 1,
                  height: 40,
                  decoration:
                      BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh),
                ),
                Text(dashboardViewModel.balanceViewModel.balances.values.first.availableBalance)
              ],
            )
          ],
        ),
      ),
    );
  }
}

class AddressRow extends StatelessWidget {
  const AddressRow(
      {super.key,
      required this.selected,
      required this.first,
      required this.last,
      required this.item,
      required this.onSelect,
      required this.walletType,
      required this.onLabelChanged,
      required this.onAddressHidden});

  final bool selected;
  final bool first;
  final bool last;
  final WalletAddressListItem item;
  final VoidCallback onSelect;
  final VoidCallback onLabelChanged;
  final VoidCallback onAddressHidden;
  final WalletType walletType;

  @override
  Widget build(BuildContext context) {
    final hasLabel = item.name != null && item.name!.isNotEmpty;

    return GestureDetector(
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: LongPressPopupBuilder(
          popup: LongPressMenu(
            items: [
              LongPressMenuItem(
                  label: "Set label",
                  iconPath: "assets/new-ui/address_set_label.svg",
                  onSelected: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    final res = await showPopUp(
                        context: context,
                        builder: (context) => getIt.get<AddressLabelInputPopup>(param1: item));

                    if (res != null) {
                      onLabelChanged();
                    }
                  }),
              LongPressMenuItem(
                  label: item.isHidden ? "Unhide address" : "Hide address",
                  iconPath: "assets/new-ui/address_hide.svg",
                  onSelected: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    onAddressHidden();
                  },
                  color: Theme.of(context).colorScheme.error),
            ],
          ),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(first ? 16 : 0),
                bottom: Radius.circular(last ? 16 : 0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                spacing: 8,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          spacing: 4,
                          children: [
                            if (hasLabel)
                              Text(
                                item.name!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500),
                              ),
                            Expanded(
                              child: AddressFormatter.buildSegmentedAddress(
                                  address: item.address,
                                  walletType: walletType,
                                  textAlign: TextAlign.left,
                                  evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: hasLabel
                                            ? Theme.of(context).colorScheme.onSurfaceVariant
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                  shouldTruncate: (hasLabel)),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Transactions: ${item.txCount}",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            Text("Balance: ${item.balance}",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        )
                      ],
                    ),
                  ),
                  if (selected) SvgPicture.asset("assets/new-ui/checkmark.svg")
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShowHiddenButton extends StatelessWidget {
  const ShowHiddenButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Material(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(Routes.receiveAddresses, arguments: true);
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Show hidden addresses"),
                      RotatedBox(
                          quarterTurns: 1,
                          child: SvgPicture.asset("assets/new-ui/dropdown_arrow.svg"))
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 1,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }
}
