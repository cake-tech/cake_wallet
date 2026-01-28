import 'dart:ui';
import 'package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cw_core/balance_card_style_settings.dart';
import 'package:cw_core/card_design.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class AccountCustomizer extends StatefulWidget {
  const AccountCustomizer({super.key, required this.accountListViewModel});

  final MoneroAccountListViewModel accountListViewModel;

  @override
  State<AccountCustomizer> createState() => _AccountCustomizerState();
}

class _AccountCustomizerState extends State<AccountCustomizer> {
  static const double _kStackVisibleFactor = 0.25;
  late final double cardWidth = MediaQuery.of(context).size.width * 0.9;

  final List<BalanceCard> _cards = [];

  @override
  void initState() {
    super.initState();
    () async {
      final settings =
          await BalanceCardStyleSettings.getAll(widget.accountListViewModel.walletInfoInternalId);

      for (int i = 0; i < widget.accountListViewModel.accounts.length; i++) {
        final setting = settings.where((e) => e.accountIndex == i).firstOrNull;

        _cards.add(BalanceCard(
          accountName: widget.accountListViewModel.accounts[i].label,
          balance: widget.accountListViewModel.accounts[i].balance ?? "0.00",
          accountBalance: widget.accountListViewModel.accounts[i].balance ?? "0.00",
          assetName: widget.accountListViewModel.currency.title,
          selected: true,
          width: cardWidth,
          design: CardDesign.fromStyleSettings(setting, widget.accountListViewModel.currency),
        ));
      }
      setState(() {});
    }.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          ModalTopBar(
            title: "Wallet Accounts",
            leadingIcon: Icon(Icons.close),
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              "Drag and drop cards to organize accounts.",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              scrollController: ModalScrollController.of(context),
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final BalanceCard item = _cards.removeAt(oldIndex);
                  _cards.insert(newIndex, item);
                });
              },
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final animValue = Curves.easeOutCubic.transform(animation.value);
                    final scale = lerpDouble(1, 1.05, animValue)!;

                    return Opacity(
                      opacity: 1 - animValue.clamp(0.0, 0.2),
                      child: Center(
                        child: SizedBox(
                          width: cardWidth,
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: _cards[index],
                );
              },
              itemCount: _cards.length,
              itemBuilder: (BuildContext context, int index) {
                final card = _cards[index];

                return Container(
                  key: ValueKey(index),
                  child: GestureDetector(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _kStackVisibleFactor,
                      child: card,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
