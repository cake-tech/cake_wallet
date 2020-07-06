import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/theme_changer.dart';
import 'package:cake_wallet/themes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/dashboard_view_model.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_store.dart';
import 'package:cake_wallet/src/stores/action_list/date_section_item.dart';
import 'package:cake_wallet/src/stores/action_list/trade_list_item.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_list_item.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'date_section_raw.dart';
import 'trade_row.dart';
import 'transaction_raw.dart';
import 'button_header.dart';
import 'package:date_range_picker/date_range_picker.dart' as date_rage_picker;

class TradeHistoryPanel extends StatefulWidget {
  TradeHistoryPanel({this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

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
    //    AnimatedContainer(
//        width: MediaQuery.of(context).size.width,
//        height: panelHeight,
//        duration: Duration(milliseconds: 1000),
//        curve: Curves.fastOutSlowIn,
//        child: )

    final transactionDateFormat = DateFormat('HH:mm');
    final _themeChanger = Provider.of<ThemeChanger>(context);
    final filterButton = Image.asset(
        _themeChanger.getTheme() == Themes.darkTheme
            ? 'assets/images/filter_button.png'
            : 'assets/images/filter_light_button.png',
        height: 36);

    return ClipRRect(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        child: Container(
            color: Colors.white,
            child: Column(children: [
              Container(
                padding:
                    EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 20),
                color: Theme.of(context).backgroundColor,
                child: Stack(
                  children: <Widget>[
                    SizedBox(height: 37), // Force stack height
                    Center(
                        child: Text(S.of(context).transactions,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .color))),
                    Positioned(
                        right: 0,
                        child: PopupMenuButton<int>(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                                enabled: false,
                                value: -1,
                                child: Text(S.of(context).transactions,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .primaryTextTheme
                                            .caption
                                            .color))),
//                          PopupMenuItem(
//                              value: 0,
//                              child: Observer(
//                                  builder: (_) => Row(
//                                      mainAxisAlignment:
//                                      MainAxisAlignment
//                                          .spaceBetween,
//                                      children: [
//                                        Text(S.of(context).incoming),
//                                        Checkbox(
//                                          value: actionListStore
//                                              .transactionFilterStore
//                                              .displayIncoming,
//                                          onChanged: (value) =>
//                                              actionListStore
//                                                  .transactionFilterStore
//                                                  .toggleIncoming(),
//                                        )
//                                      ]))),
//                          PopupMenuItem(
//                              value: 1,
//                              child: Observer(
//                                  builder: (_) => Row(
//                                      mainAxisAlignment:
//                                      MainAxisAlignment
//                                          .spaceBetween,
//                                      children: [
//                                        Text(S.of(context).outgoing),
//                                        Checkbox(
//                                          value: actionListStore
//                                              .transactionFilterStore
//                                              .displayOutgoing,
//                                          onChanged: (value) =>
//                                              actionListStore
//                                                  .transactionFilterStore
//                                                  .toggleOutgoing(),
//                                        )
//                                      ]))),
                            PopupMenuItem(
                                value: 2,
                                child:
                                    Text(S.of(context).transactions_by_date)),
                            PopupMenuDivider(),
                            PopupMenuItem(
                                enabled: false,
                                value: -1,
                                child: Text(S.of(context).trades,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .primaryTextTheme
                                            .caption
                                            .color))),
                            PopupMenuItem(
                                value: 3,
                                child: Observer(
                                    builder: (_) => Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('XMR.TO'),
//                                        Checkbox(
//                                          value: actionListStore
//                                              .tradeFilterStore
//                                              .displayXMRTO,
//                                          onChanged: (value) =>
//                                              actionListStore
//                                                  .tradeFilterStore
//                                                  .toggleDisplayExchange(
//                                                  ExchangeProviderDescription
//                                                      .xmrto),
//                                        )
                                            ]))),
                            PopupMenuItem(
                                value: 4,
                                child: Observer(
                                    builder: (_) => Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Change.NOW'),
//                                        Checkbox(
//                                          value: actionListStore
//                                              .tradeFilterStore
//                                              .displayChangeNow,
//                                          onChanged: (value) =>
//                                              actionListStore
//                                                  .tradeFilterStore
//                                                  .toggleDisplayExchange(
//                                                  ExchangeProviderDescription
//                                                      .changeNow),
//                                        )
                                            ]))),
                            PopupMenuItem(
                                value: 5,
                                child: Observer(
                                    builder: (_) => Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('MorphToken'),
//                                        Checkbox(
//                                          value: actionListStore
//                                              .tradeFilterStore
//                                              .displayMorphToken,
//                                          onChanged: (value) =>
//                                              actionListStore
//                                                  .tradeFilterStore
//                                                  .toggleDisplayExchange(
//                                                  ExchangeProviderDescription
//                                                      .morphToken),
//                                        )
                                            ])))
                          ],
                          child: filterButton,
                          onSelected: (item) async {
                            if (item == 2) {
                              final picked =
                                  await date_rage_picker.showDatePicker(
                                      context: context,
                                      initialFirstDate: DateTime.now()
                                          .subtract(Duration(days: 1)),
                                      initialLastDate: (DateTime.now()),
                                      firstDate: DateTime(2015),
                                      lastDate: DateTime.now()
                                          .add(Duration(days: 1)));

                              if (picked != null && picked.length == 2) {
//                              actionListStore.transactionFilterStore
//                                  .changeStartDate(picked.first);
//                              actionListStore.transactionFilterStore
//                                  .changeEndDate(picked.last);
                              }
                            }
                          },
                        )),
                  ],
                ),
              ),
              widget.dashboardViewModel.transactions?.isNotEmpty ?? false
                  ? ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: widget.dashboardViewModel.transactions.length,
                      itemBuilder: (_, index) {
                        final item =
                            widget.dashboardViewModel.transactions[index];

                        if (item is DateSectionItem) {
                          return DateSectionRaw(date: item.date);
                        }

                        if (item is TransactionListItem) {
                          final transaction = item.transaction;
                          final savedDisplayMode = BalanceDisplayMode.all;
                          //settingsStore
//                                      .balanceDisplayMode;
                          final formattedAmount = savedDisplayMode ==
                                  BalanceDisplayMode.hiddenBalance
                              ? '---'
                              : transaction.amountFormatted();
                          final formattedFiatAmount = savedDisplayMode ==
                                  BalanceDisplayMode.hiddenBalance
                              ? '---'
                              : transaction.fiatAmount(); // symbol ???

                          return TransactionRow(
                              onTap: () => Navigator.of(context).pushNamed(
                                  Routes.transactionDetails,
                                  arguments: transaction),
                              direction: transaction.direction,
                              formattedDate: transactionDateFormat
                                  .format(transaction.date),
                              formattedAmount: formattedAmount,
                              formattedFiatAmount: formattedFiatAmount,
                              isPending: transaction.isPending);
                        }

                        if (item is TradeListItem) {
                          final trade = item.trade;
                          final savedDisplayMode = BalanceDisplayMode.all;
                          //settingsStore
                          //  .balanceDisplayMode;
                          final formattedAmount = trade.amount != null
                              ? savedDisplayMode ==
                                      BalanceDisplayMode.hiddenBalance
                                  ? '---'
                                  : trade.amountFormatted()
                              : trade.amount;

                          return TradeRow(
                              onTap: () => Navigator.of(context).pushNamed(
                                  Routes.tradeDetails,
                                  arguments: trade),
                              provider: trade.provider,
                              from: trade.from,
                              to: trade.to,
                              createdAtFormattedDate:
                                  transactionDateFormat.format(trade.createdAt),
                              formattedAmount: formattedAmount);
                        }

                        return Container(
                            color: Theme.of(context).backgroundColor,
                            height: 1);
                      },
                      separatorBuilder: (_, __) =>
                          Container(height: 14, color: Colors.white),
                    )
                  : Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Your transactions will be displayed here!',
                          style: TextStyle(color: Colors.grey)))
            ]))); //,
  }
}
