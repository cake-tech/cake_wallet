import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/anonpay_history_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_order_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_trade_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/payjoin_history_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/transaction_details_modal.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/dashboard/anonpay_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';

class HistorySection extends StatelessWidget {
  const HistorySection(
      {super.key,
      required this.dashboardViewModel,
      required this.short,
      required this.roundedTopSection,
      required this.detailsAsPage});

  final DashboardViewModel dashboardViewModel;
  final bool short;
  final bool roundedTopSection;
  final bool detailsAsPage;

  /// A history row is a single button node: every text inside it (direction,
  /// date, amounts) merges into one label.
  Widget _historyRow({required VoidCallback onTap, required Widget child}) => MergeSemantics(
        child: Semantics(
          button: true,
          child: GestureDetector(onTap: onTap, child: child),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
        padding: EdgeInsets.only(left: 16.0, right: 16, top: short && roundedTopSection ? 18 : 0),
        sliver: Observer(
          builder: (_) {
            final localeName = Localizations.localeOf(context).toString();
            final items = short ? dashboardViewModel.itemsShort : dashboardViewModel.items;

            return (items.isEmpty)
                ? SliverPadding(
                    padding: EdgeInsets.only(top: 24),
                    sliver: SliverToBoxAdapter(
                      child: (dashboardViewModel.status is SyncingSyncStatus)
                          ? SizedBox.shrink()
                          : Center(
                              child: Text(S.of(context).transactions_will_appear_here,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.only(bottom: short ? 0 : 144),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: items.length,
                        (context, index) => Observer(builder: (_) {
                          final prevItem = index == 0 ? null : items[index - 1];
                          final topPadding = index == 0 ? 0.0 : 18.0;
                          final item = items[index];
                          final nextItem = index == items.length - 1 ? null : items[index + 1];

                          final roundedBottom = (nextItem == null || nextItem is DateSectionItem);
                          final roundedTop = roundedTopSection &&
                              (prevItem == null || prevItem is DateSectionItem);

                          if (item is TransactionListItem) {
                            final transaction = item.transaction;
                            final transactionType =
                                dashboardViewModel.getTransactionType(transaction);

                            if (item.hasTokens && item.assetOfTransaction == null) {
                              return Container();
                            }

                            CryptoCurrency? asset;
                            if (transaction.additionalInfo["isLightning"] == true)
                              asset = CryptoCurrency.btcln;
                            else
                              asset = item.assetOfTransaction;

                            return _historyRow(
                              onTap: () {
                                final page =
                                    getIt.get<TransactionDetailsModal>(param1: transaction);
                                if (detailsAsPage) {
                                  Navigator.of(context).push(CupertinoPageRoute(
                                      builder: (context) => Material(child: page)));
                                } else {
                                  showModalBottomSheet(
                                      isScrollControlled: true,
                                      context: context,
                                      builder: (context) =>
                                          FractionallySizedBox(heightFactor: 0.9, child: page));
                                }
                              },
                              child: HistoryTile(
                                title: item.formattedTitle + transactionType,
                                date: _formatTransactionDate(item.date, localeName),
                                amount: item.formattedCryptoAmount,
                                amountFiat: item.formattedFiatAmount,
                                hasTokens: item.hasTokens,
                                chainIconPath: _getChainIconPath(),
                                roundedBottom: roundedBottom,
                                roundedTop: roundedTop,
                                bottomSeparator: !roundedBottom,
                                direction: item.transaction.direction,
                                pending: item.transaction.isPending,
                                asset: asset,
                              ),
                            );
                          } else if (item is TradeListItem) {
                            final trade = item.trade;
                            final tradeFrom = trade.from;
                            final tradeTo = trade.to;

                            return _historyRow(
                              onTap: () => Navigator.of(context)
                                  .pushNamed(Routes.tradeDetails, arguments: trade),
                              child: HistoryTradeTile(
                                from: tradeFrom,
                                to: tradeTo,
                                provider: trade.provider,
                                date: _formatTransactionDate(
                                    item.trade.createdAt ?? DateTime.now(), localeName),
                                amount: dashboardViewModel.balanceDisplayMode ==
                                        BalanceDisplayMode.hiddenBalance
                                    ? "---"
                                    : trade.amountFormatted(),
                                receiveAmount: dashboardViewModel.balanceDisplayMode ==
                                        BalanceDisplayMode.hiddenBalance
                                    ? "---"
                                    : trade.receiveAmountFormatted(),
                                roundedBottom: roundedBottom,
                                roundedTop: roundedTop,
                                bottomSeparator: !roundedBottom,
                                swapState: trade.state,
                              ),
                            );
                          } else if (item is SpecificDateSectionItem) {
                            return Padding(
                                padding: EdgeInsets.only(left: 8.0, bottom: 8.0, top: topPadding),
                                child: Text(item.text,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant)));
                          } else if (item is DateSectionItem) {
                            return Padding(
                                padding: EdgeInsets.only(left: 8.0, bottom: 8.0, top: topPadding),
                                child: Text(DateFormat("MMMM yyyy", localeName).format(item.date),
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant)));
                          } else if (item is OrderListItem) {
                            return _historyRow(
                              onTap: () => Navigator.of(context)
                                  .pushNamed(Routes.orderDetails, arguments: item.order),
                              child: HistoryOrderTile(
                                date: _formatTransactionDate(item.order.createdAt, localeName),
                                amount: item.orderFormattedAmount,
                                amountFiat: "",
                                roundedBottom: roundedBottom,
                                roundedTop: roundedTop,
                                bottomSeparator: !roundedBottom,
                              ),
                            );
                          } else if (item is PayjoinTransactionListItem) {
                            final session = item.session;

                            return _historyRow(
                              onTap: () => Navigator.of(context).pushNamed(
                                Routes.payjoinDetails,
                                arguments: [item.sessionId, item.transaction],
                              ),
                              child: PayjoinHistoryTile(
                                  createdAt:
                                      _formatTransactionDate(session.inProgressSince!, localeName),
                                  amount: dashboardViewModel.appStore.amountParsingProxy
                                      .asDisplayString(Money(session.amount, CryptoCurrency.btc)),
                                  currency: item.transaction?.from ?? "BTC",
                                  state: item.status,
                                  isSending: session.isSenderSession,
                                  roundedTop: roundedTop,
                                  roundedBottom: roundedBottom,
                                  bottomSeparator: !roundedBottom),
                            );
                          } else if (item is AnonpayTransactionListItem) {
                            final transactionInfo = item.transaction;

                            return _historyRow(
                                onTap: () => Navigator.of(context).pushNamed(
                                    Routes.anonPayDetailsPage,
                                    arguments: transactionInfo),
                                child: AnonpayHistoryTile(
                                    provider: transactionInfo.provider,
                                    createdAt: _formatTransactionDate(
                                        transactionInfo.createdAt, localeName),
                                    amount: transactionInfo.fiatAmount?.toString() ??
                                        (transactionInfo.amountTo?.toString() ?? ''),
                                    currency: transactionInfo.fiatAmount != null
                                        ? transactionInfo.fiatEquiv ?? ''
                                        : CryptoCurrency.fromFullName(transactionInfo.coinTo)
                                            .name
                                            .toUpperCase(),
                                    roundedTop: roundedTop,
                                    roundedBottom: roundedBottom,
                                    bottomSeparator: !roundedBottom));
                          } else
                            return Text(item.runtimeType.toString());
                        }),
                      ),
                    ),
                  );
          },
        ));
  }

  String _getChainIconPath() {
    try {
      return CryptoCurrency.fromString(
              dashboardViewModel.wallet.currency.tag ?? dashboardViewModel.wallet.currency.title)
          .chainIconPath!;
    } catch (e) {
      return dashboardViewModel.wallet.currency.chainIconPath ?? "";
    }
  }

  String _formatTransactionDate(DateTime date, String localeName) {
    final time = DateFormat.Hm(localeName);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(date.year, date.month, date.day);
    final daysAgo = today.difference(thatDay).inDays;

    final timeStr = time.format(date);

    if (daysAgo == 0) {
      return timeStr;
    }

    if (daysAgo == 1) {
      return "${S.current.yesterday}, $timeStr";
    }

    if (daysAgo < 7) {
      final weekday = DateFormat.EEEE(localeName).format(date);
      return "$weekday, $timeStr";
    }

    if (date.year == now.year) {
      final dayMonth = DateFormat("d MMMM", localeName).format(date);
      return "$dayMonth, $timeStr";
    }

    final full = DateFormat("d MMM yyyy", localeName).format(date);
    return "$full, $timeStr";
  }
}
