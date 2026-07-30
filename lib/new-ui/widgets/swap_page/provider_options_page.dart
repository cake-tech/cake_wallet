import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_selector.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/new-ui/viewmodels/swap/swap_bloc.dart";
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/trocador_providers_settings.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/settings/trocador_providers_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:flutter_bloc/flutter_bloc.dart";
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ProviderOptionsPage extends StatelessWidget {
  const ProviderOptionsPage({super.key, required this.bloc});

  final SwapBloc bloc;

  @override
  Widget build(BuildContext context) => BlocBuilder<SwapBloc, SwapState>(
      bloc: bloc,
      builder: (context, state) {
        if(state case final SwapInputState s) {
          final decentralizedProviders = s.availableProviders
              .where((provider) => !provider.isCentralized)
              .toList();
          final centralizedProviders =s.availableProviders
              .where((provider) => provider.isCentralized)
              .toList();
          return Column(
            children: [
              ModalTopBar(
                title: S.of(context).swap_providers,
                onLeadingPressed: Navigator.of(context).pop,
                leadingIcon: const Icon(Icons.arrow_back_ios_new),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        NewListSections(sections: {
                          "": [
                            ListItemSelector(
                                options: [
                                  s.forceDecentralizedProviders
                                      ? S.of(context).decentralized_only
                                      : S.of(context).best_rate
                                ],
                                keyValue: "pref",
                                label: S.of(context).preference,
                                onTap: ()=>bloc.add(ForceDecentralizedExchangesToggled()))
                          ]
                        }),
                        SizedBox(height: 24),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(
                            S.of(context).decentralized,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          Row(
                            spacing: 20,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  for (final provider in decentralizedProviders) {
                                    if(!s.enabledProviders.contains(provider))
                                      bloc.add(ProviderToggled(provider));
                                  }
                                },
                                child: Text(
                                  S.of(context).select_all,
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  for (final provider in decentralizedProviders) {
                                    if(s.enabledProviders.contains(provider)) {
                                      bloc.add(ProviderToggled(provider));
                                    }
                                  }
                                },
                                child: Text(S.of(context).unselect_all,
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                              )
                            ],
                          )
                        ]),
                        SizedBox(height: 12),
                        NewListSections(
                            getCheckboxValue: (key) =>
                            s.enabledProviders
                                .firstWhereOrNull((e) => e.title == key) !=
                                null,
                            updateCheckboxValue: (key, val) {},
                            sections: {
                              S.of(context).decentralized: decentralizedProviders.map((item) => ListItemCheckbox(
                                    iconPath: item.image,
                                    keyValue: item.title,
                                    label: item.title,
                                    value: s.enabledProviders.contains(item),
                                    onChanged: (val) {
                                      bloc.add(ProviderToggled(item));
                                    })).toList(),
                            }),
                        SizedBox(height: 24),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(S.of(context).centralized,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          Row(
                            spacing: 20,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  for (final provider in decentralizedProviders) {
                                    if(!s.enabledProviders.contains(provider))
                                      bloc.add(ProviderToggled(provider));
                                  }
                                },
                                child: Text(
                                  S.of(context).select_all,
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  for (final provider in decentralizedProviders) {
                                    if(s.enabledProviders.contains(provider))
                                    bloc.add(ProviderToggled(provider));
                                  }
                                },
                                child: Text(S.of(context).unselect_all,
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                              )
                            ],
                          )
                        ]),
                        SizedBox(height: 12),
                        Stack(
                          children: [
                            NewListSections(
                                getCheckboxValue: (key) =>
                                s.enabledProviders
                                    .firstWhereOrNull((e) => e.title == key) !=
                                    null,
                                updateCheckboxValue: (key, val) {},
                                sections: {
                                  S.of(context).centralized: centralizedProviders.map((item) => ListItemCheckbox(
                                        iconPath: item.image,
                                        keyValue: item.title,
                                        label: item.title,
                                        showArrow: item.title == "Trocador",
                                        value: s.enabledProviders.contains(item),
                                        subtitle: item.title == "Trocador"
                                            ? S.of(context).manage_providers
                                            : null,
                                        onTap: item.title == "Trocador"
                                            ? () {
                                          _openTrocadorProvidersPage(context);
                                        }
                                            : null,
                                        onChanged: (val) {
                                          bloc.add(ProviderToggled(item));
                                        })).toList(),
                                }),
                            if (s.forceDecentralizedProviders)
                              Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.black12.withAlpha(128),
                                        borderRadius: BorderRadius.circular(16)),
                                  ))
                          ],
                        ),
                        SizedBox(height: 36)
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        } return SizedBox.shrink();

      },
    );

  void _openTrocadorProvidersPage(BuildContext context) {
    final vm = getIt.get<TrocadorProvidersViewModel>();
    Navigator.of(context).push(CupertinoPageRoute(
        builder: (context) => Material(
                child: TrocadorProvidersSettings(
              trocadorProvidersViewModel: vm,
            ))));
  }
}
