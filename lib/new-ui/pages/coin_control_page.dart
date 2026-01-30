import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coin_control_page/coin_control_list_item.dart';
import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import "package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart";

class NewCoinControlPage extends StatefulWidget {
  const NewCoinControlPage({super.key, required this.unspentCoinsListViewModel});

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  State<NewCoinControlPage> createState() => _NewCoinControlPageState();
}

class _NewCoinControlPageState extends State<NewCoinControlPage> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = widget.unspentCoinsListViewModel.initialSetup();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.unspentCoinsListViewModel.isSavingItems,
      child: Material(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          child: Column(
            children: [
              ModalTopBar(
                  title: "Coin Control",
                  onLeadingPressed: Navigator.of(context).pop,
                  leadingIcon: Icon(Icons.arrow_back_ios_new),
                  onTrailingPressed: () {}),
              FutureBuilder(
                  future: _initialization,
                  builder: (context, asyncSnapshot) {
                    if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                      return Expanded(
                        child: Center(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 12,
                          children: [
                            CupertinoActivityIndicator(),
                            Text("${S.of(context).loading}...")
                          ],
                        )),
                      );
                    }

                    if (asyncSnapshot.hasError)
                      return Center(child: Text(S.of(context).coin_control_load_failed));

                    return Expanded(
                      child: SingleChildScrollView(
                        child: SafeArea(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                                child: ModalHeader(
                                    iconPath: "assets/new-ui/settings_row_icons/coin-control.svg",
                                    title: "Coin Control",
                                    message: S.of(context).coin_control_desc),
                              ),
                              if (widget.unspentCoinsListViewModel.items.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    spacing: 20,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          widget.unspentCoinsListViewModel.toggleSelectAll(true);
                                        },
                                        child: Text(S.of(context).select_all,
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400)),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          widget.unspentCoinsListViewModel.toggleSelectAll(false);
                                        },
                                        child: Text(S.of(context).unselect_all,
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400)),
                                      )
                                    ],
                                  ),
                                ),
                              if (widget.unspentCoinsListViewModel.nonFrozenItems.isEmpty &&
                                  widget.unspentCoinsListViewModel.frozenItems.isEmpty) ...[
                                SizedBox(height: 12),
                                Center(
                                    child: Text(
                                  S.of(context).no_unspent_coins,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                )),
                              ],
                              Observer(
                                builder: (_) => widget
                                        .unspentCoinsListViewModel.nonFrozenItems.isEmpty
                                    ? SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: CoinControlListSection(
                                            items: widget.unspentCoinsListViewModel.nonFrozenItems,
                                            unspentCoinsListViewModel:
                                                widget.unspentCoinsListViewModel),
                                      ),
                              ),
                              Observer(
                                builder: (context) =>
                                    widget.unspentCoinsListViewModel.frozenItems.isEmpty
                                        ? SizedBox.shrink()
                                        : Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                            child: Column(
                                                spacing: 10,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(height: 12),
                                                  Text(
                                                    S.of(context).frozen,
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w400,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant),
                                                  ),
                                                  CoinControlListSection(
                                                      items: widget
                                                          .unspentCoinsListViewModel.frozenItems,
                                                      unspentCoinsListViewModel:
                                                          widget.unspentCoinsListViewModel),
                                                ]),
                                          ),
                              ),
                              SizedBox(height: 12)
                            ],
                          ),
                        ),
                      ),
                    );
                  })
            ],
          ),
        ),
      ),
    );
  }
}

class CoinControlListSection extends StatelessWidget {
  const CoinControlListSection(
      {super.key, required this.items, required this.unspentCoinsListViewModel});

  final List<UnspentCoinsItem> items;
  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => Container(
        height: 1,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      itemBuilder: (_, int index) {
        return Observer(builder: (_) {
          final item = items[index];
          final fiatAmount = unspentCoinsListViewModel.fiatAmounts[item.hash] ?? '';
          return GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(
              Routes.unspentCoinsDetails,
              arguments: [item, unspentCoinsListViewModel],
            ),
            child: CoinControlListItem(
              note: item.note,
              amount: item.amount,
              fiatAmount: fiatAmount,
              address: item.address,
              isSending: item.isSending,
              isFrozen: item.isFrozen,
              isChange: item.isChange,
              isSilentPayment: item.isSilentPayment,
              isLoading: item.isBeingSaved,
              isFirst: index == 0,
              isLast: index == items.length - 1,
              onCheckBoxTap: item.isFrozen
                  ? null
                  : () async {
                      item.isSending = !item.isSending;
                      await unspentCoinsListViewModel.saveUnspentCoinInfo(item);
                    },
            ),
          );
        });
      },
    );
  }
}
