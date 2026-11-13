import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_row.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/sync_status.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class HistorySection extends StatelessWidget {
  const HistorySection({
    required this.dashboardViewModel,
    required this.short,
    required this.roundedTopSection,
    required this.detailsAsPage,
    super.key,
  });

  final DashboardViewModel dashboardViewModel;
  final bool short;
  final bool roundedTopSection;
  final bool detailsAsPage;

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: EdgeInsets.only(left: 16, right: 16, top: short && roundedTopSection ? 18 : 0),
        // Tracks only `items`. Items are plain objects, so a change inside one (a transaction
        // confirming) shows only when the view model recomputes `items` and this rebuilds every
        // built row (for transactions, see _lastTxContentByIdentity in DashboardViewModel).
        sliver: Observer(
          builder: (_) {
            final items = short ? dashboardViewModel.itemsShort : dashboardViewModel.items;

            return (items.isEmpty)
                ? SliverPadding(
                    padding: const EdgeInsets.only(top: 24),
                    sliver: SliverToBoxAdapter(
                      child: (dashboardViewModel.status is SyncingSyncStatus)
                          ? const SizedBox.shrink()
                          : Center(
                              child: Text(
                                S.of(context).transactions_will_appear_here,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.only(bottom: short ? 0 : 144),
                    sliver: SliverList(
                      // Rows get their item and neighbours from this same `items` snapshot that
                      // sets childCount, so a row can never index past the end of the list.
                      delegate: SliverChildBuilderDelegate(
                        childCount: items.length,
                        (context, index) => HistoryRow(
                          dashboardViewModel: dashboardViewModel,
                          item: items[index],
                          prevItem: index == 0 ? null : items[index - 1],
                          nextItem: index == items.length - 1 ? null : items[index + 1],
                          roundedTopSection: roundedTopSection,
                          detailsAsPage: detailsAsPage,
                        ),
                      ),
                    ),
                  );
          },
        ),
      );
}
