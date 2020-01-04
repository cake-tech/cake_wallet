import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:date_range_picker/date_range_picker.dart' as DateRagePicker;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_store.dart';
import 'package:cake_wallet/src/stores/balance/balance_store.dart';
import 'package:cake_wallet/src/stores/sync/sync_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/action_list/date_section_item.dart';
import 'package:cake_wallet/src/stores/action_list/trade_list_item.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_list_item.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/date_section_raw.dart';
import 'package:cake_wallet/src/screens/dashboard/trade_row.dart';
import 'package:cake_wallet/src/screens/dashboard/transaction_raw.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/dashboard/wallet_menu.dart';
import 'package:cake_wallet/src/widgets/picker.dart';

class DashboardPage extends BasePage {
  final _bodyKey = GlobalKey();

  @override
  Widget leading(BuildContext context) {
    return SizedBox(
        width: 30,
        child: FlatButton(
            padding: EdgeInsets.all(0),
            onPressed: () => _presentWalletMenu(context),
            child: Image.asset('assets/images/more.png',
                color: Theme.of(context).primaryTextTheme.caption.color,
                width: 30)));
  }

  @override
  Widget middle(BuildContext context) {
    final walletStore = Provider.of<WalletStore>(context);

    return Observer(builder: (_) {
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              walletStore.name,
              style: TextStyle(
                  color: Theme.of(context).primaryTextTheme.title.color),
            ),
            SizedBox(height: 5),
            Text(
              walletStore.account != null ? '${walletStore.account.label}' : '',
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                  color: Theme.of(context).primaryTextTheme.title.color),
            ),
          ]);
    });
  }

  @override
  Widget trailing(BuildContext context) {
    return SizedBox(
      width: 20,
      child: FlatButton(
          padding: EdgeInsets.all(0),
          onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
          child: Image.asset('assets/images/settings_icon.png',
              color: Colors.grey, height: 20)),
    );
  }

  @override
  Widget body(BuildContext context) => DashboardPageBody(key: _bodyKey);

  @override
  Widget floatingActionButton(BuildContext context) => FloatingActionButton(
      child: Image.asset('assets/images/exchange_icon.png',
          color: Colors.white, height: 26, width: 22),
      backgroundColor: Palette.floatingActionButton,
      onPressed: () async {
        final actionListStore = Provider.of<ActionListStore>(context);

        await Navigator.of(context, rootNavigator: true)
          .pushNamed(Routes.exchange);
        actionListStore.updateTradeList();  
      });

  void _presentWalletMenu(BuildContext bodyContext) {
    final walletMenu = WalletMenu(bodyContext);

    showDialog(
        builder: (_) => Picker(
            items: walletMenu.items,
            selectedAtIndex: -1,
            title: S.of(bodyContext).wallet_menu,
            pickerHeight: 510,
            onItemSelected: (item) =>
                walletMenu.action(walletMenu.items.indexOf(item))),
        context: bodyContext);
  }
}

class DashboardPageBody extends StatefulWidget {
  DashboardPageBody({Key key}) : super(key: key);

  @override
  DashboardPageBodyState createState() => DashboardPageBodyState();
}

class DashboardPageBodyState extends State<DashboardPageBody> {
  static final transactionDateFormat = DateFormat("MMM d, yyyy HH:mm");

  final _connectionStatusObserverKey = GlobalKey();
  final _balanceObserverKey = GlobalKey();
  final _balanceTitleObserverKey = GlobalKey();
  final _syncingObserverKey = GlobalKey();
  final _listObserverKey = GlobalKey();
  final _listKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final balanceStore = Provider.of<BalanceStore>(context);
    final actionListStore = Provider.of<ActionListStore>(context);
    final syncStore = Provider.of<SyncStore>(context);
    final settingsStore = Provider.of<SettingsStore>(context);

    return Observer(
        key: _listObserverKey,
        builder: (_) {
          final items =
              actionListStore.items == null ? [] : actionListStore.items;
          final itemsCount = items.length + 2;

          return ListView.builder(
              key: _listKey,
              padding: EdgeInsets.only(bottom: 15),
              itemCount: itemsCount,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Theme.of(context).backgroundColor,
                        boxShadow: [
                          BoxShadow(
                              color: Palette.shadowGreyWithOpacity,
                              blurRadius: 10,
                              offset: Offset(0, 12))
                        ]),
                    child: Column(
                      children: <Widget>[
                        Observer(
                            key: _syncingObserverKey,
                            builder: (_) {
                              final status = syncStore.status;
                              final statusText = status.title();
                              final progress = syncStore.status.progress();
                              final isFialure = status is FailedSyncStatus;

                              var descriptionText = '';

                              if (status is SyncingSyncStatus) {
                                descriptionText = S
                                    .of(context)
                                    .Blocks_remaining(
                                        syncStore.status.toString());
                              }

                              if (status is FailedSyncStatus) {
                                descriptionText = S
                                    .of(context)
                                    .please_try_to_connect_to_another_node;
                              }

                              return Container(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 3,
                                      child: LinearProgressIndicator(
                                        backgroundColor: Palette.separator,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Palette.cakeGreen),
                                        value: progress,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(statusText,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isFialure
                                                ? Palette.failure
                                                : Palette.cakeGreen)),
                                    Text(descriptionText,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Palette.wildDarkBlue,
                                            height: 2.0))
                                  ],
                                ),
                              );
                            }),
                        GestureDetector(
                          onTapUp: (_) => balanceStore.isReversing = false,
                          onTapDown: (_) => balanceStore.isReversing = true,
                          child: Container(
                            padding: EdgeInsets.only(top: 40, bottom: 40),
                            color: Colors.transparent,
                            child: Column(
                              children: <Widget>[
                                Container(width: double.infinity),
                                Observer(
                                    key: _balanceTitleObserverKey,
                                    builder: (_) {
                                      final savedDisplayMode =
                                          settingsStore.balanceDisplayMode;
                                      final displayMode =
                                          balanceStore.isReversing
                                              ? (savedDisplayMode ==
                                                      BalanceDisplayMode
                                                          .availableBalance
                                                  ? BalanceDisplayMode
                                                      .fullBalance
                                                  : BalanceDisplayMode
                                                      .availableBalance)
                                              : savedDisplayMode;
                                      var title = displayMode.toString();

                                      return Text(title,
                                          style: TextStyle(
                                              color: Palette.violet,
                                              fontSize: 16));
                                    }),
                                Observer(
                                    key: _connectionStatusObserverKey,
                                    builder: (_) {
                                      final savedDisplayMode =
                                          settingsStore.balanceDisplayMode;
                                      var balance = '---';
                                      final displayMode =
                                          balanceStore.isReversing
                                              ? (savedDisplayMode ==
                                                      BalanceDisplayMode
                                                          .availableBalance
                                                  ? BalanceDisplayMode
                                                      .fullBalance
                                                  : BalanceDisplayMode
                                                      .availableBalance)
                                              : savedDisplayMode;

                                      if (displayMode ==
                                          BalanceDisplayMode.availableBalance) {
                                        balance =
                                            balanceStore.unlockedBalance ??
                                                '0.0';
                                      }

                                      if (displayMode ==
                                          BalanceDisplayMode.fullBalance) {
                                        balance =
                                            balanceStore.fullBalance ?? '0.0';
                                      }

                                      return Text(
                                        balance,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .primaryTextTheme
                                                .caption
                                                .color,
                                            fontSize: 42),
                                      );
                                    }),
                                Padding(
                                    padding: EdgeInsets.only(top: 7),
                                    child: Observer(
                                        key: _balanceObserverKey,
                                        builder: (_) {
                                          final savedDisplayMode =
                                              settingsStore.balanceDisplayMode;
                                          final displayMode =
                                              balanceStore.isReversing
                                                  ? (savedDisplayMode ==
                                                          BalanceDisplayMode
                                                              .availableBalance
                                                      ? BalanceDisplayMode
                                                          .fullBalance
                                                      : BalanceDisplayMode
                                                          .availableBalance)
                                                  : savedDisplayMode;
                                          final symbol = settingsStore
                                              .fiatCurrency
                                              .toString();
                                          var balance = '---';

                                          if (displayMode ==
                                              BalanceDisplayMode
                                                  .availableBalance) {
                                            balance =
                                                '${balanceStore.fiatUnlockedBalance} $symbol';
                                          }

                                          if (displayMode ==
                                              BalanceDisplayMode.fullBalance) {
                                            balance =
                                                '${balanceStore.fiatFullBalance} $symbol';
                                          }

                                          return Text(balance,
                                              style: TextStyle(
                                                  color: Palette.wildDarkBlue,
                                                  fontSize: 16));
                                        }))
                              ],
                            ),
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(
                                left: 35, right: 35, bottom: 30),
                            child: Container(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                      child: PrimaryImageButton(
                                    image: Image.asset(
                                        'assets/images/send_icon.png',
                                        height: 25,
                                        width: 25),
                                    text: S.of(context).send,
                                    onPressed: () => Navigator.of(context,
                                            rootNavigator: true)
                                        .pushNamed(Routes.send),
                                    color: Theme.of(context)
                                        .primaryTextTheme
                                        .button
                                        .backgroundColor,
                                    borderColor: Theme.of(context)
                                        .primaryTextTheme
                                        .button
                                        .decorationColor,
                                  )),
                                  SizedBox(width: 10),
                                  Expanded(
                                      child: PrimaryImageButton(
                                    image: Image.asset(
                                        'assets/images/receive_icon.png',
                                        height: 25,
                                        width: 25),
                                    text: S.of(context).receive,
                                    onPressed: () => Navigator.of(context,
                                            rootNavigator: true)
                                        .pushNamed(Routes.receive),
                                    color: Theme.of(context)
                                        .accentTextTheme
                                        .caption
                                        .backgroundColor,
                                    borderColor: Theme.of(context)
                                        .accentTextTheme
                                        .caption
                                        .decorationColor,
                                  ))
                                ],
                              ),
                            )),
                      ],
                    ),
                  );
                }

                if (index == 1 && actionListStore.totalCount > 0) {
                  return Padding(
                    padding: EdgeInsets.only(right: 20, top: 10, bottom: 20),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          PopupMenuButton<int>(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  enabled: false,
                                  value: -1,
                                  child: Text(S.of(context).transactions,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black))),
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
                                          color: Colors.black))),
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
                                              ])))
                            ],
                            child: Text(S.of(context).filters,
                                style: TextStyle(
                                    fontSize: 16.0,
                                    color: Theme.of(context)
                                        .primaryTextTheme
                                        .subtitle
                                        .color)),
                            onSelected: (item) async {
                              if (item == 2) {
                                final List<DateTime> picked =
                                    await DateRagePicker.showDatePicker(
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
                          )
                        ]),
                  );
                }

                index -= 2;

                if (index < 0 || index >= items.length) {
                  return Container();
                }

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
                          : transaction.fiatAmount();

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
                          : trade.amount
                      : trade.amount;

                  return TradeRow(
                      onTap: () => Navigator.of(context)
                          .pushNamed(Routes.tradeDetails, arguments: trade),
                      provider: trade.provider,
                      from: trade.from,
                      to: trade.to,
                      createdAtFormattedDate:
                          DateFormat("dd.MM.yyyy, H:m").format(trade.createdAt),
                      formattedAmount: formattedAmount);
                }

                return Container();
              });
        });
  }
}
