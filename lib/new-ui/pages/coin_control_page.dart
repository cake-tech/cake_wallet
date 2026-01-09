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
      child: SafeArea(
        bottom: false,
        child: Material(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Column(
              spacing: 12,
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
                              CupertinoActivityIndicator(
                              ),
                              Text("Loading...")
                            ],
                          )),
                        );
                      }

                      if (asyncSnapshot.hasError)
                        return Center(child: Text('Failed to load unspent coins'));

                      return Column(
                        children: [
                          ModalHeader(
                            iconPath: "assets/new-ui/settings_row_icons/coin-control.svg",
                            title: "Coin Control",
                            message:
                                "Filter outputs for this transaction. The changes you make here will only reflect on the current transaction.",
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
                                    child: Text("Select all",
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400)),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      widget.unspentCoinsListViewModel.toggleSelectAll(false);
                                    },
                                    child: Text("Unselect all",
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400)),
                                  )
                                ],
                              ),
                            ),
                          SizedBox(height: 15),
                          if(widget.unspentCoinsListViewModel.nonFrozenItems.isEmpty && widget.unspentCoinsListViewModel.frozenItems.isEmpty)
                          Center(
                              child: Text(
                                'No unspent coins available',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              )),
                          SizedBox(height: 15),
                          Observer(
                            builder: (_)=>widget.unspentCoinsListViewModel.nonFrozenItems.isEmpty
                                ? SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: CoinControlListSection(items: widget.unspentCoinsListViewModel.nonFrozenItems, unspentCoinsListViewModel: widget.unspentCoinsListViewModel),
                                  ),
                          ),
                          Observer(
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Column(
                                  spacing: 10,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.unspentCoinsListViewModel.frozenItems.isNotEmpty)
                                      Text("Frozen", style: TextStyle(fontSize: 14,fontWeight: FontWeight.w400,color: Theme.of(context).colorScheme.onSurfaceVariant),),
                                    if (widget.unspentCoinsListViewModel.frozenItems.isNotEmpty)
                                      CoinControlListSection(
                                          items: widget.unspentCoinsListViewModel.frozenItems,
                                          unspentCoinsListViewModel:
                                              widget.unspentCoinsListViewModel),
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      );
                    })
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CoinControlListSection extends StatelessWidget {
  const CoinControlListSection({super.key, required this.items, required this.unspentCoinsListViewModel});

  final List<UnspentCoinsItem> items;
  final UnspentCoinsListViewModel unspentCoinsListViewModel;


  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 15),
      itemBuilder: (_, int index) {
        return Observer(builder: (_) {
          final item = items[index];
          final fiatAmount =
              unspentCoinsListViewModel.fiatAmounts[item.hash] ??
              '';
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
              isLast: index ==
                  items.length - 1,
              onCheckBoxTap: item.isFrozen
                  ? null
                  : () async {
                item.isSending = !item.isSending;
                await unspentCoinsListViewModel
                    .saveUnspentCoinInfo(item);
              },
            ),
          );
        });
      },
    );
  }
}

