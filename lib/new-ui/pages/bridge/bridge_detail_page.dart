import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/address_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/bridge/bridge_details_view_model.dart';
import 'package:cw_core/generate_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BridgeDetailPage extends StatelessWidget {
  BridgeDetailPage({super.key, required this.viewModel});

  final BridgeDetailsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.9],
      builder: (context, controller) {
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    ModalTopBar(
                      title: "Bridge Transfer Details",
                      leadingIcon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      leadingSemanticLabel: S.of(context).seed_alert_back,
                      onLeadingPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            NewListSections(
                              sections: {
                                "": viewModel.items
                                    .where((item) => item is! TrackTradeListItem)
                                    .map((item) {
                                  return ListItemRegularRow(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: item.value));
                                      showBar<void>(context, S.of(context).copied_to_clipboard);
                                    },
                                    showArrow: false,
                                    keyValue: item.title,
                                    label: item.title,
                                    trailingWidget: _buildTrailingWidget(item, context),
                                    bottomWidget: _buildBottomWidget(item, context),
                                  );
                                }).toList(),
                              },
                            ),
                            SizedBox(height: 16),
                            NewListSections(sections: {
                              "": viewModel.items
                                  .where((item) => item is TrackTradeListItem)
                                  .map((item) {
                                return ListItemRegularRow(
                                  keyValue: "view tx on",
                                  label: item.title,
                                  onTap: () => (item as TrackTradeListItem).onTap(),
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                  trailingIconPath: "assets/new-ui/link_arrow.svg",
                                  trailingIconSize: 8,
                                );
                              }).toList()
                            }),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).viewPadding.bottom)
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomWidget(TransactionDetailsListItem item, BuildContext context) {
    if (item is AddressListItem) {
      return AddressFormatter.buildSegmentedAddress(
          address: item.value,
          evenTextStyle: TextStyle(
              fontSize: 12,
              fontFamily: "IBM Plex Mono",
              color: Theme.of(context).colorScheme.onSurface));
    }

    final isCompleted = item.value.contains("Completed");
    final isInitiated = item.value.contains("initiated");
    if (isCompleted || isInitiated) {
      return Row(
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: isCompleted ? CustomThemeColors.syncGreen : CustomThemeColors.syncYellow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1.5,
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            item.value,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildTrailingWidget(TransactionDetailsListItem item, BuildContext context) {
    final isCompleted = item.value.contains("Completed");
    final isInitiated = item.value.contains("initiated");
    if (item is AddressListItem || isCompleted || isInitiated) {
      return SizedBox.shrink();
    }

    return Text(
      item.value.capitalized(),
      style: TextStyle(
        fontWeight: FontWeight.w400,
        fontFamily: 'Wix Madefor Text',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
