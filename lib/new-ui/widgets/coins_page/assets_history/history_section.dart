import "package:cake_wallet/anonpay/anonpay_invoice_info.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/transaction_history/sources/store_sources.dart";
import "package:cake_wallet/new-ui/viewmodels/transaction_history/transaction_history_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/anonpay_history_tile.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_order_tile.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_trade_tile.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/payjoin_history_tile.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/transaction_details_modal.dart";
import "package:cake_wallet/order/order.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/view_model/dashboard/date_section_item.dart";
import "package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart";
import "package:cw_core/action_list_item.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/transaction_info.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:intl/intl.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class HistorySectionArguments {
  const HistorySectionArguments({
    required this.short,
    required this.roundedTopSection,
    required this.detailsAsPage,
  });

  final bool short;
  final bool roundedTopSection;
  final bool detailsAsPage;
}

class HistorySection extends StatelessWidget {
  const HistorySection(
      {
      required this.bloc,
      required this.payjoinEmitter,
      required this.short,
      required this.roundedTopSection,
      required this.detailsAsPage, super.key,});

  final TransactionHistoryBloc bloc;
  final PayjoinHistoryEmitter payjoinEmitter;
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
  Widget build(BuildContext context) => SliverPadding(
        padding: EdgeInsets.only(left: 16, right: 16, top: short && roundedTopSection ? 18 : 0),
        sliver: BlocBuilder<TransactionHistoryBloc, TransactionHistoryState>(
          bloc: bloc,
          builder: (context, state) {
            final localeName = Localizations.localeOf(context).toString();

            if (state is TransactionHistoryNotLoaded) {
              return const SliverPadding(
                padding: EdgeInsets.only(top: 24),
                sliver: SliverToBoxAdapter(
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              );
            }

            final loaded = state as TransactionHistoryLoaded;
            final items = short
                ? loaded.items.take(shortHistoryLength).toList()
                : loaded.sectioned;

            return (items.isEmpty)
                ? SliverPadding(
                    padding: const EdgeInsets.only(top: 24),
                    sliver: SliverToBoxAdapter(
                      child: Observer(
                        builder: (_) => (bloc.appStore.wallet!.syncStatus
                                is SyncingSyncStatus)
                            ? const SizedBox.shrink()
                            : Center(
                                child: Text(S.of(context).transactions_will_appear_here,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,),),
                              ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.only(bottom: short ? 0 : 144),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: items.length,
                        (context, index)  {
                          final prevItem = index == 0 ? null : items[index - 1];
                          final topPadding = index == 0 ? 0.0 : 18.0;
                          final item = _asPayjoin(items[index]) ?? items[index];
                          final nextItem = index == items.length - 1 ? null : items[index + 1];

                          final roundedBottom = nextItem == null || nextItem is DateSectionItem;
                          final roundedTop = roundedTopSection &&
                              (prevItem == null || prevItem is DateSectionItem);

                          if (item is TransactionInfo) {
                            return _historyRow(
                              onTap: () {
                                final page =
                                getIt.get<TransactionDetailsModal>(param1: item);
                                if (detailsAsPage) {
                                  Navigator.of(context).push(CupertinoPageRoute(
                                      builder: (context) => Material(child: page),),);
                                } else {
                                  showMaterialModalBottomSheet(
                                      backgroundColor: Colors.transparent,
                                      context: context,
                                      builder: (context) =>
                                          FractionallySizedBox(heightFactor: 0.9, child: page),);
                                }
                              },
                              child: HistoryTile(
                                title: _formattedTitle(context, item),
                                date: _formatTransactionDate(item.date, localeName),
                                amount: item.amount,
                                amountFiat: bloc.fiatConversionStore.convertSync(item.amount, bloc.fiat),
                                hasTokens: bloc.appStore.wallet!.hasTokens,
                                chainIconPath: _getChainIconPath(),
                                roundedBottom: roundedBottom,
                                roundedTop: roundedTop,
                                bottomSeparator: !roundedBottom,
                                direction: item.direction,
                                pending: item.isPending,
                                asset: item.assetOfTransaction,
                              ),
                            );
                          } else if (item is Trade) {
                            final trade = item;
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
                                    item.createdAt ?? DateTime.now(), localeName,),
                                amount: trade.amountFormatted(),
                                receiveAmount: trade.receiveAmountFormatted(),
                                roundedBottom: roundedBottom,
                                roundedTop: roundedTop,
                                bottomSeparator: !roundedBottom,
                                swapState: trade.state,
                              ),
                            );
                          } else if (item is SpecificDateSectionItem) {
                            return Padding(
                                padding: EdgeInsets.only(left: 8, bottom: 8, top: topPadding),
                                child: Text(item.text,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,),),);
                          } else if (item is DateSectionItem) {
                            return Padding(
                                padding: EdgeInsets.only(left: 8, bottom: 8, top: topPadding),
                                child: Text(DateFormat("MMMM yyyy", localeName).format(item.date),
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,),),);
                          } else if (item is Order) {
                            return _historyRow(
                              onTap: () => Navigator.of(context)
                                  .pushNamed(Routes.orderDetails, arguments: item),
                              child: HistoryOrderTile(
                                date: _formatTransactionDate(item.createdAt, localeName),
                                amount: Money.safeParse(item.amount, bloc.appStore.wallet!.currency),
                                amountFiat:  Money.zero(bloc.fiat),
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
                                  amount: Money(session.amount, CryptoCurrency.btc),
                                  currency: item.transaction?.from ?? "BTC",
                                  state: item.status,
                                  isSending: session.isSenderSession,
                                  roundedTop: roundedTop,
                                  roundedBottom: roundedBottom,
                                  bottomSeparator: !roundedBottom,),
                            );
                          } else if (item is AnonpayInvoiceInfo) {

                            return _historyRow(
                                onTap: () => Navigator.of(context).pushNamed(
                                    Routes.anonPayDetailsPage,
                                    arguments: item,),
                                child: AnonpayHistoryTile(
                                    provider: item.provider,
                                    createdAt: _formatTransactionDate(
                                        item.createdAt, localeName,),
                                    amount: Money.tryParse(item.amountTo.toString(), CryptoCurrency.xmr) ?? Money.zero(CryptoCurrency.xmr),
                                    roundedTop: roundedTop,
                                    roundedBottom: roundedBottom,
                                    bottomSeparator: !roundedBottom,),);
                          } else {
                          return kDebugMode ? Text(item.runtimeType.toString()) : const SizedBox.shrink();
                        }
                      }
                      ),
                    ),
                  );
          },
        ),);

  static const shortHistoryLength = 3;

  PayjoinTransactionListItem? _asPayjoin(HistoryListItem item) =>
      item is TransactionInfo ? payjoinEmitter.forTransaction(item) : null;

  String _getChainIconPath() {
    final currency = bloc.appStore.wallet!.currency;
    try {
      return CryptoCurrency.fromString(currency.tag ?? currency.title).chainIconPath!;
    } catch (e) {
      return currency.chainIconPath ?? "";
    }
  }

  String _formattedTitle(BuildContext context, TransactionInfo transaction) {
    final localizations = S.of(context);
    final title = localizations.getByKey(transaction.title);

    if (!transaction.hasStatus) {
      return title;
    }

    final status = transaction.status;
    return status == null ? "$title..." : "$title ${localizations.getByKey(status)}";
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
