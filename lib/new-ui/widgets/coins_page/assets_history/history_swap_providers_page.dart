import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/select_deselect_all.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class HistorySwapProvidersPage extends StatelessWidget {
  const HistorySwapProvidersPage({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).filter_swap_providers,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.of(context).seed_alert_back,
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
              child: SingleChildScrollView(
            controller: ModalScrollController.of(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Observer(
                builder: (_) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Material(
                        color: Colors.transparent,
                        child: SelectDeselectAllBar(
                            title: S.of(context).swap_providers,
                            onSelected: (val) {
                              if ((val &&
                                      dashboardViewModel.tradeFilterStore.enabledProvidersCount ==
                                          0) ||
                                  (!val &&
                                      dashboardViewModel.tradeFilterStore.enabledProvidersCount >
                                          0)) {
                                dashboardViewModel.tradeFilterStore
                                    .toggleDisplayExchange(ExchangeProviderDescription.all);
                              }
                            }),
                      ),
                    ),
                    NewListSections(sections: {
                      "": dashboardViewModel.exchangeFilterItems
                          .whereType<SwapProviderFilterItem>()
                          .map((item) => ListItemCheckbox(
                              iconPath: item.providerDescription.image,
                              keyValue: item.caption,
                              label: item.caption,
                              value: item.value(),
                              onChanged: (val) => dashboardViewModel.tradeFilterStore
                                  .toggleDisplayExchange(item.providerDescription)))
                          .toList()
                    }),
                  ],
                ),
              ),
            ),
          ))
        ],
      ),
    );
  }
}
