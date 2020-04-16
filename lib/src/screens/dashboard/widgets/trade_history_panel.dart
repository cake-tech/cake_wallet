import 'dart:async';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_store.dart';
import 'package:cake_wallet/src/stores/action_list/date_section_item.dart';
import 'package:cake_wallet/src/stores/action_list/trade_list_item.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_list_item.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/routes.dart';
import 'date_section_raw.dart';
import 'trade_row.dart';
import 'transaction_raw.dart';

class TradeHistoryPanel extends StatefulWidget {
  @override
  TradeHistoryPanelState createState() => TradeHistoryPanelState();
}

class TradeHistoryPanelState extends State<TradeHistoryPanel> {
  final _listObserverKey = GlobalKey();
  final _listKey = GlobalKey();

  double panelHeight;
  double screenHeight;
  double opacity;
  bool isDraw;

  @override
  void initState() {
    panelHeight = 0;
    screenHeight = 0;
    opacity = 0;
    isDraw = false;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    screenHeight = MediaQuery.of(context).size.height;
    setState(() {
      panelHeight = screenHeight;
      opacity = 1;
    });
    Timer(Duration(milliseconds: 350), () =>
        setState(() => isDraw = true)
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionListStore = Provider.of<ActionListStore>(context);
    final settingsStore = Provider.of<SettingsStore>(context);
    final transactionDateFormat = DateFormat("HH:mm");
    final filterButton = Image.asset('assets/images/filter_button.png');

    return Container(
      width: double.infinity,
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        width: double.infinity,
        height: panelHeight,
        duration: Duration(milliseconds: 1000),
        curve: Curves.fastOutSlowIn,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            color: PaletteDark.historyPanel.withOpacity(opacity),
        ),
        child: isDraw
        ? Container(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                height: 36,
                margin: EdgeInsets.only(bottom: 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Text(
                      S.of(context).trade_history_title,
                      style: TextStyle(
                        fontSize: 20
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () {},
                        child: filterButton,
                      )
                    )
                  ],
                ),
              ),
              Observer(
                key: _listObserverKey,
                builder: (_) {
                  final items = actionListStore.items == null
                      ? <String>[]
                      : actionListStore.items;
                  final itemsCount = items.length;
                  final symbol = settingsStore.fiatCurrency.toString();

                  return Expanded(
                      child: ListView.builder(
                          key: _listKey,
                          padding: EdgeInsets.only(bottom: 15),
                          itemCount: itemsCount,
                          itemBuilder: (context, index) {

                            final item = items[index];

                            if (item is DateSectionItem) {
                              return DateSectionRaw(date: item.date);
                            }

                            if (item is TransactionListItem) {
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

                            return Container();
                          }
                      )
                  );
                })
            ],
          ),
        )
        : Offstage()
      ),
    );
  }
}