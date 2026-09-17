import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_swap_providers_page.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/select_deselect_all.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class HistoryFiltersPage extends StatelessWidget {
  const HistoryFiltersPage({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).filters,
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
                            title: S.of(context).type,
                            onSelected: dashboardViewModel.changeAllFilterItems),
                      ),
                    ),
                    NewListSections(
                      sections: {
                        "": dashboardViewModel.filterItems.map((item) {
                          if (item is SwapFilterItem) {
                            final String subtitle;
                            final Color subtitleColor;
                            if (dashboardViewModel.tradeFilterStore.displayAllTrades) {
                              subtitle = S.of(context).manage_providers;
                              subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;
                            } else if (dashboardViewModel.tradeFilterStore.enabledProvidersCount ==
                                0) {
                              subtitle = S.of(context).no_providers_selected;
                              subtitleColor = Color(0xFFFFB84E);
                            } else {
                              subtitle = "${item.enabledProviders()} ${S.of(context).providers}";
                              subtitleColor = Theme.of(context).colorScheme.primary;
                            }

                            return ListItemCheckbox(
                                onTap: () {
                                  Navigator.of(context).push(CupertinoPageRoute(
                                      builder: (context) => HistorySwapProvidersPage(
                                          dashboardViewModel: dashboardViewModel)));
                                },
                                keyValue: item.caption,
                                label: S.of(context).swap,
                                value: item.value(),
                                onChanged: (val) {
                                  if ((val &&
                                          dashboardViewModel
                                                  .tradeFilterStore.enabledProvidersCount ==
                                              0) ||
                                      (!val &&
                                          dashboardViewModel
                                                  .tradeFilterStore.enabledProvidersCount >
                                              0)) {
                                    dashboardViewModel.tradeFilterStore
                                        .toggleDisplayExchange(ExchangeProviderDescription.all);
                                  }
                                },
                                subtitle: subtitle,
                                subtitleColor: subtitleColor,
                                showArrow: true);
                          }

                          return ListItemCheckbox(
                              keyValue: item.caption,
                              label: item.caption,
                              value: item.value(),
                              onChanged: (val) => item.onChanged());
                        }).toList()
                      },
                    ),
                  ],
                ),
              ),
            ),
          )),
          SafeArea(
              child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: NewPrimaryButton(
                onPressed: () => dashboardViewModel.changeAllFilterItems(true),
                text: S.of(context).reset_filters,
                color: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.primary),
          ))
        ],
      ),
    );
  }
}
