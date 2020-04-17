import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_store.dart';
import 'package:cake_wallet/src/stores/action_list/date_section_item.dart';
import 'package:cake_wallet/src/stores/action_list/trade_list_item.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_list_item.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:date_range_picker/date_range_picker.dart' as date_rage_picker;

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
        duration: Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
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
                  double freeSpaceHeight = MediaQuery.of(context).size.height - 496; // FIXME

                  return SliverList(
                    key: _listKey,
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {

                        if (index == itemsCount - 1) {
                          freeSpaceHeight = freeSpaceHeight >= 0 ? freeSpaceHeight : 0;

                          return Container(
                            height: freeSpaceHeight,
                            width: MediaQuery.of(context).size.width,
                            color: PaletteDark.historyPanel,
                          );
                        }

                        final item = items[index];

                        if (item is DateSectionItem) {
                          freeSpaceHeight -= 32; // FIXME
                          return DateSectionRaw(date: item.date);
                        }

                        if (item is TransactionListItem) {
                          freeSpaceHeight -= 45; // FIXME
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
                          freeSpaceHeight -= 45; // FIXME
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
                          color: PaletteDark.historyPanel
                        );
                      },

                      childCount: itemsCount
                    )
                  );
                })
          ],
        )
      ),
    );
  }
}

class ButtonHeader extends SliverPersistentHeaderDelegate {
  final sendImage = Image.asset('assets/images/send.png');
  final exchangeImage = Image.asset('assets/images/exchange.png');
  final buyImage = Image.asset('assets/images/coins.png');
  final filterButton = Image.asset('assets/images/filter_button.png');

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final actionListStore = Provider.of<ActionListStore>(context);
    final historyPanelWidth = MediaQuery.of(context).size.width;

    double buttonsOpacity = 1 - shrinkOffset / (maxExtent - minExtent);
    double buttonsHeight = maxExtent - minExtent - shrinkOffset;

    buttonsOpacity = buttonsOpacity >= 0 ? buttonsOpacity : 0;
    buttonsHeight = buttonsHeight >= 0 ? buttonsHeight : 0;

    return Stack(
      fit: StackFit.expand,
      overflow: Overflow.visible,
      children: <Widget>[
        Opacity(
          opacity: buttonsOpacity,
          child: Container(
            height: buttonsHeight,
            padding: EdgeInsets.only(left: 44, right: 44),
            child: Row(
              children: <Widget>[
                Flexible(
                    child: actionButton(
                        context: context,
                        image: sendImage,
                        title: S.of(context).send,
                        route: Routes.send
                    )
                ),
                Flexible(
                    child: actionButton(
                        context: context,
                        image: exchangeImage,
                        title: S.of(context).exchange,
                        route: Routes.exchange
                    )
                ),
                Flexible(
                    child: actionButton(
                        context: context,
                        image: buyImage,
                        title: S.of(context).buy,
                        route: ''
                    )
                )
              ],
            ),
          ),
        ),
        Positioned(
          top: buttonsHeight,
          left: 0,
          child: Container(
            width: historyPanelWidth,
            height: 66,
            padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              color: PaletteDark.historyPanel,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Text(
                  S.of(context).trade_history_title,
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white
                  ),
                ),
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
                                    color: Theme.of(context).primaryTextTheme.caption.color))),
                        PopupMenuItem(
                            value: 0,
                            child: Observer(
                                builder: (_) => Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text(S.of(context).incoming),
                                      Checkbox(
                                        value: actionListStore
                                            .transactionFilterStore
                                            .displayIncoming,
                                        onChanged: (value) =>
                                            actionListStore
                                                .transactionFilterStore
                                                .toggleIncoming(),
                                      )
                                    ]))),
                        PopupMenuItem(
                            value: 1,
                            child: Observer(
                                builder: (_) => Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text(S.of(context).outgoing),
                                      Checkbox(
                                        value: actionListStore
                                            .transactionFilterStore
                                            .displayOutgoing,
                                        onChanged: (value) =>
                                            actionListStore
                                                .transactionFilterStore
                                                .toggleOutgoing(),
                                      )
                                    ]))),
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
                                    color: Theme.of(context).primaryTextTheme.caption.color))),
                        PopupMenuItem(
                            value: 3,
                            child: Observer(
                                builder: (_) => Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text('XMR.TO'),
                                      Checkbox(
                                        value: actionListStore
                                            .tradeFilterStore
                                            .displayXMRTO,
                                        onChanged: (value) =>
                                            actionListStore
                                                .tradeFilterStore
                                                .toggleDisplayExchange(
                                                ExchangeProviderDescription
                                                    .xmrto),
                                      )
                                    ]))),
                        PopupMenuItem(
                            value: 4,
                            child: Observer(
                                builder: (_) => Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text('Change.NOW'),
                                      Checkbox(
                                        value: actionListStore
                                            .tradeFilterStore
                                            .displayChangeNow,
                                        onChanged: (value) =>
                                            actionListStore
                                                .tradeFilterStore
                                                .toggleDisplayExchange(
                                                ExchangeProviderDescription
                                                    .changeNow),
                                      )
                                    ]))),
                        PopupMenuItem(
                            value: 5,
                            child: Observer(
                                builder: (_) => Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text('MorphToken'),
                                      Checkbox(
                                        value: actionListStore
                                            .tradeFilterStore
                                            .displayMorphToken,
                                        onChanged: (value) =>
                                            actionListStore
                                                .tradeFilterStore
                                                .toggleDisplayExchange(
                                                ExchangeProviderDescription
                                                    .morphToken),
                                      )
                                    ])))
                      ],
                      child: filterButton,
                      onSelected: (item) async {
                        if (item == 2) {
                          final List<DateTime> picked =
                          await date_rage_picker.showDatePicker(
                              context: context,
                              initialFirstDate: DateTime.now()
                                  .subtract(Duration(days: 1)),
                              initialLastDate: (DateTime.now()),
                              firstDate: DateTime(2015),
                              lastDate: DateTime.now()
                                  .add(Duration(days: 1)));

                          if (picked != null && picked.length == 2) {
                            actionListStore.transactionFilterStore
                                .changeStartDate(picked.first);
                            actionListStore.transactionFilterStore
                                .changeEndDate(picked.last);
                          }
                        }
                      },
                    ),
                )
              ],
            ),
          )
        )
      ],
    );
  }

  @override
  double get maxExtent => 174;

  @override
  double get minExtent => 66;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;

  Widget actionButton({
    BuildContext context,
    @required Image image,
    @required String title,
    @required String route}) {

    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              if (route.isNotEmpty) {
                Navigator.of(context, rootNavigator: true).pushNamed(route);
              }
            },
            child: Container(
              height: 48,
              width: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle
              ),
              child: image,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 16,
                  color: PaletteDark.walletCardText
              ),
            ),
          )
        ],
      ),
    );
  }
}