import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/pages/bridge/bridge_detail_page.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/view_model/bridge/bridge_history_view_model.dart';
import 'package:cake_wallet/new-ui/widgets/bridge/transfer_history_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BridgeHistoryPage extends StatelessWidget {
  BridgeHistoryPage(this.viewModel);

  final BridgeHistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          ModalTopBar(
            title: "Bridge history",
            leadingIcon: const Icon(Icons.arrow_back_ios_new, size: 18),
            leadingSemanticLabel: S.of(context).seed_alert_back,
            onLeadingPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Observer(
              builder: (_) {
                if (viewModel.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "No bridge transfers yet.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                final active = viewModel.activeTransfers;
                final past = viewModel.pastTransfers;
                final items = <Widget>[];

                if (active.isNotEmpty) {
                  items.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "In progress",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  );
                  for (final transfer in active) {
                    items.add(
                      TransferHistoryRow(
                        transfer: transfer,
                        onTap: () {
                          final page = getIt.get<BridgeDetailPage>(param1: transfer);
                          showModalBottomSheet(
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            context: context,
                            builder: (context) => page,
                          );
                        },
                      ),
                    );
                  }
                }

                if (past.isNotEmpty) {
                  items.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top: 16),
                      child: Text(
                        "Past",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  );
                  for (final transfer in past) {
                    items.add(
                      TransferHistoryRow(
                        transfer: transfer,
                        onTap: () {
                          final page = getIt.get<BridgeDetailPage>(param1: transfer);
                          showModalBottomSheet(
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            context: context,
                            builder: (context) => page,
                          );
                        },
                      ),
                    );
                  }
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  children: items,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
