import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ProviderSelectorPage extends StatelessWidget {
  const ProviderSelectorPage({super.key, required this.exchangeViewModel});

  final ExchangeViewModel exchangeViewModel;

  @override
  Widget build(BuildContext context) {
    final decentralizedProviders =
        exchangeViewModel.selectedProviders.where((item) => !item.description.isCentralized);
    final centralizedProviders =
        exchangeViewModel.selectedProviders.where((item) => item.description.isCentralized);

    return Column(
      children: [
        ModalTopBar(
          title: S.of(context).change_provider,
          leadingIcon: Icon(Icons.arrow_back_ios_new),
          onLeadingPressed: Navigator.of(context).maybePop,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: ModalScrollController.of(context),
            child: Column(
              spacing: 24,
              children: [
                Text(
                    "${S.of(context).change_provider_desc_1}\n${S.of(context).change_provider_desc_2}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: NewListSections(
                    showHeader: true,
                    getCheckboxValue: (_) => exchangeViewModel.forcedProvider == null,
                    updateCheckboxValue: (key, value) {},
                    sections: {
                      if (exchangeViewModel.bestRateProvider != null)
                        S.of(context).best_rate: [
                          ListItemCheckbox(
                              iconPath: exchangeViewModel.bestRateProvider!.description.image,
                              keyValue: "bestrate",
                              label: exchangeViewModel.bestRateProvider!.title,
                              subtitle:
                                  exchangeViewModel.bestRateProvider!.description.isCentralized
                                      ? S.of(context).centralized
                                      : S.of(context).decentralized,
                              value: exchangeViewModel.forcedProvider == null,
                              onChanged: (val) {
                                exchangeViewModel.setForcedProvider(null);
                                Navigator.of(context).pop();
                              }),
                        ],
                      S.of(context).decentralized: decentralizedProviders
                          .map((item) => ListItemRegularRow(
                              iconPath: item.description.image,
                              keyValue: item.title,
                              label: item.title,
                              onTap: () {
                                exchangeViewModel.setForcedProvider(item);
                                Navigator.of(context).pop();
                              }))
                          .toList(),
                      S.of(context).centralized: centralizedProviders
                          .map((item) => ListItemRegularRow(
                              iconPath: item.description.image,
                              keyValue: item.title,
                              label: item.title,
                              onTap: () {
                                exchangeViewModel.setForcedProvider(item);
                                Navigator.of(context).pop();
                              }))
                          .toList(),
                    },
                  ),
                ),
                SizedBox(height: 18),
              ],
            ),
          ),
        )
      ],
    );
  }
}
