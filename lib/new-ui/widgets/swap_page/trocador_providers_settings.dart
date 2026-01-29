import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/settings/trocador_providers_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class TrocadorProvidersSettings extends StatelessWidget {
  const TrocadorProvidersSettings({super.key, required this.trocadorProvidersViewModel});

  final TrocadorProvidersViewModel trocadorProvidersViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 24,
        children: [
          ModalTopBar(
            title: "Trocador ${S.of(context).providers}",
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ModalHeader(
                          title: "${S.of(context).about} Trocador",
                          iconPath: "assets/new-ui/trade_providers/trocador.svg",
                          message:
                              "Trocador ${S.of(context).trocador_desc}"),
                      SizedBox(),
                      Text(S.of(context).providers),
                      Text(
                        S.of(context).trocador_desc_kyc,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      SizedBox(),
                      Observer(
                        builder: (_) {
                          if (trocadorProvidersViewModel.isLoading) {
                            return Center(child: CircularProgressIndicator());
                          }
                          final providerStates = trocadorProvidersViewModel.providerStates;
                          final providerRatings = trocadorProvidersViewModel.providerRatings;
                          if (providerStates.isEmpty) {
                            return Center(child: Text(S.of(context).no_providers_available));
                          }
                          return NewListSections(
                              getCheckboxValue: (key) => providerStates[key] ?? false,
                              updateCheckboxValue: (key, val) {},
                              sections: {
                                "": [
                                  for (var providerName in providerStates.keys)
                                    ListItemToggle(
                                        keyValue: providerName,
                                        label: providerName,
                                        value: providerStates[providerName] ?? false,
                                        onChanged: (val) {
                                          trocadorProvidersViewModel
                                              .toggleProviderState(providerName);
                                        },
                                        leadingEndWidget: providerRatings[providerName] == null
                                            ? null
                                            : Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        width: 1),
                                                    borderRadius: BorderRadius.circular(99999)),
                                                child: Center(
                                                  child: Text(
                                                    providerRatings[providerName] ?? "",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        height: 1),
                                                  ),
                                                ),
                                              ))
                                ]
                              });
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
