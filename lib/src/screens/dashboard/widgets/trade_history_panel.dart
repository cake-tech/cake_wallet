import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_store.dart';
import 'package:cake_wallet/src/stores/action_list/date_section_item.dart';
import 'package:cake_wallet/src/stores/action_list/trade_list_item.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_list_item.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/routes.dart';
import 'date_section_raw.dart';
import 'trade_row.dart';
import 'transaction_raw.dart';
import 'button_header.dart';

class TradeHistoryPanel extends StatefulWidget {
  @override
  TradeHistoryPanelState createState() => TradeHistoryPanelState();
}

class TradeHistoryPanelState extends State<TradeHistoryPanel> {
  final _listObserverKey = GlobalKey();
  final _listKey = GlobalKey();

  double panelHeight;
  double screenHeight;

  @override
  void initState() {
    panelHeight = 0;
    screenHeight = 0;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    screenHeight = MediaQuery.of(context).size.height;
    setState(() {
      panelHeight = screenHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final actionListStore = Provider.of<ActionListStore>(context);
    final settingsStore = Provider.of<SettingsStore>(context);
    final transactionDateFormat = DateFormat("HH:mm");

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        width: MediaQuery.of(context).size.width,
        height: panelHeight,
        duration: Duration(milliseconds: 1000),
        curve: Curves.fastOutSlowIn,
        child: ClipRRect(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverPersistentHeader(
                delegate: ButtonHeader(),
                pinned: true,
                floating: false,
              ),
              Observer(
                  key: _listObserverKey,
                  builder: (_) {
                    final items = actionListStore.items == null
                        ? <String>[]
                        : actionListStore.items;
                    final itemsCount = items.length + 1;
                    final symbol = settingsStore.fiatCurrency.toString();
                    double freeSpaceHeight = MediaQuery.of(context).size.height - 496;

                    return SliverList(
                        key: _listKey,
                        delegate: SliverChildBuilderDelegate(
                                (context, index) {

                              if (index == itemsCount - 1) {
                                freeSpaceHeight = freeSpaceHeight >= 0 ? freeSpaceHeight : 0;

                                return Container(
                                  height: freeSpaceHeight,
                                  width: MediaQuery.of(context).size.width,
                                  color: Theme.of(context).backgroundColor,
                                );
                              }

                              final item = items[index];

                              if (item is DateSectionItem) {
                                freeSpaceHeight -= 38;
                                return DateSectionRaw(date: item.date);
                              }

                              if (item is TransactionListItem) {
                                freeSpaceHeight -= 62;
                                final transaction = item.transaction;
                                final savedDisplayMode = settingsStore.balanceDisplayMode;
                                final formattedAmount =
                                savedDisplayMode == BalanceDisplayMode.hiddenBalance
                                    ? '---'
                                    : transaction.amountFormatted();
                                final formattedFiatAmount =
                                savedDisplayMode == BalanceDisplayMode.hiddenBalance
                                    ? '---'
                                    : transaction.fiatAmount(symbol);

                                return TransactionRow(
                                    onTap: () => Navigator.of(context).pushNamed(
                                        Routes.transactionDetails,
                                        arguments: transaction),
                                    direction: transaction.direction,
                                    formattedDate:
                                    transactionDateFormat.format(transaction.date),
                                    formattedAmount: formattedAmount,
                                    formattedFiatAmount: formattedFiatAmount,
                                    isPending: transaction.isPending);
                              }

                              if (item is TradeListItem) {
                                freeSpaceHeight -= 62;
                                final trade = item.trade;
                                final savedDisplayMode = settingsStore.balanceDisplayMode;
                                final formattedAmount = trade.amount != null
                                    ? savedDisplayMode == BalanceDisplayMode.hiddenBalance
                                    ? '---'
                                    : trade.amountFormatted()
                                    : trade.amount;

                                return TradeRow(
                                    onTap: () => Navigator.of(context)
                                        .pushNamed(Routes.tradeDetails, arguments: trade),
                                    provider: trade.provider,
                                    from: trade.from,
                                    to: trade.to,
                                    createdAtFormattedDate:
                                    transactionDateFormat.format(trade.createdAt),
                                    formattedAmount: formattedAmount);
                              }

                              return Container(
                                  color: Theme.of(context).backgroundColor
                              );
                            },

                            childCount: itemsCount
                        )
                    );
                  })
            ],
          ),
        )
      ),
    );
  }
}