import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/standard_list_status_row.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/bridge_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BridgeDetailPage extends StatelessWidget {
  BridgeDetailPage({super.key, required this.viewModel});

  final BridgeDetailsViewModel viewModel;

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
            title: "Bridge Transfer Details",
            leadingIcon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onLeadingPressed: () => Navigator.of(context).pop(),
          ),
          BridgeDetailPageBody(viewModel),
        ],
      ),
    );
  }
}

class BridgeDetailPageBody extends StatefulWidget {
  BridgeDetailPageBody(this.viewModel);

  final BridgeDetailsViewModel viewModel;

  @override
  State<BridgeDetailPageBody> createState() => BridgeDetailPageBodyState();
}

class BridgeDetailPageBodyState extends State<BridgeDetailPageBody> {
  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final itemsCount = widget.viewModel.items.length;

        return SectionStandardList(
          sectionCount: 1,
          itemCounter: (_) => itemsCount,
          itemBuilder: (_, index) {
            final item = widget.viewModel.items[index];

            if (item is DetailsListStatusItem) {
              return StandardListStatusRow(
                title: item.title,
                value: item.value,
                status: item.status,
              );
            }

            if (item is TrackTradeListItem) {
              return ListRow(
                title: item.title,
                value: item.value,
                hintTextColor: Theme.of(context).colorScheme.onSurfaceVariant,
                textWidget: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item.value));
                    showBar<void>(context, S.of(context).copied_to_clipboard);
                  },
                  child: Text(
                    item.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                image: GestureDetector(
                  onTap: item.onTap,
                  child: Icon(
                    Icons.launch_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            }

            final isError = item.title == "Error";
            return GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: item.value));
                showBar<void>(context, S.of(context).copied_to_clipboard);
              },
              child: ListRow(
                title: item.title,
                value: item.value,
                hintTextColor: Theme.of(context).colorScheme.onSurfaceVariant,
                mainTextColor: isError ? Theme.of(context).colorScheme.error : null,
              ),
            );
          },
        );
      },
    );
  }
}
