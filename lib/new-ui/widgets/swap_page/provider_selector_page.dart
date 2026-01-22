import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
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
          title: "Change Provider",
          leadingIcon: Icon(Icons.arrow_back_ios_new),
          onLeadingPressed: Navigator.of(context).maybePop,
        ),
        SingleChildScrollView(
          controller: ModalScrollController.of(context),
          child: Column(
            spacing: 24,
            children: [
              Text(
                  "Select a provider from your whitelisted options.\nYou can manage your options from the swap configuration.",
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
                    "Best rate": [
                      ListItemCheckbox(
                          iconPath: exchangeViewModel.bestRateProvider!.description.image,
                          keyValue: "bestrate",
                          label: exchangeViewModel.bestRateProvider!.title,
                          subtitle: exchangeViewModel.bestRateProvider!.description.isCentralized
                              ? "Centralized"
                              : "Decentralized",
                          value: exchangeViewModel.forcedProvider == null,
                          onChanged: (val) {
                            exchangeViewModel.setForcedProvider(null);
                            Navigator.of(context).pop();
                          }),
                    ],
                    "Decentralized": decentralizedProviders
                        .map((item) => ListItemRegularRow(
                            iconPath: item.description.image,
                            keyValue: item.title,
                            label: item.title,
                            onTap: () {
                              exchangeViewModel.setForcedProvider(item);
                              Navigator.of(context).pop();
                            }))
                        .toList(),
                    "Centralized": centralizedProviders
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
              )
            ],
          ),
        )
      ],
    );
  }
}
