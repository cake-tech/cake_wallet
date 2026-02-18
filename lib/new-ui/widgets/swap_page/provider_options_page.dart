import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_selector.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/trocador_providers_settings.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cake_wallet/view_model/settings/trocador_providers_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ProviderOptionsPage extends StatelessWidget {
  const ProviderOptionsPage({super.key, required this.exchangeViewModel});

  final ExchangeViewModel exchangeViewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final decentralizedProviders = exchangeViewModel.providerList
            .where((provider) => !provider.description.isCentralized)
            .toList();
        final centralizedProviders = exchangeViewModel.providerList
            .where((provider) => provider.description.isCentralized)
            .toList();
        return Column(
          children: [
            ModalTopBar(
              title: S.of(context).swap_providers,
              onLeadingPressed: Navigator.of(context).pop,
              leadingIcon: Icon(Icons.arrow_back_ios_new),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      NewListSections(sections: {
                        "": [
                          ListItemSelector(
                              options: [
                                exchangeViewModel.forceDecentralizedExchanges
                                    ? S.of(context).decentralized_only
                                    : S.of(context).best_rate
                              ],
                              keyValue: "pref",
                              label: S.of(context).preference,
                              onTap: exchangeViewModel.toggleForceDecentralizedExchanges)
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
                                  _switchProviderStatus(provider, true, context);
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
                                  _switchProviderStatus(provider, false, context);
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
                              exchangeViewModel.selectedProviders
                                  .firstWhereOrNull((e) => e.title == key) !=
                              null,
                          updateCheckboxValue: (key, val) {},
                          sections: {
                            S.of(context).decentralized: decentralizedProviders.map((item) {
                              return ListItemCheckbox(
                                  iconPath: item.description.image,
                                  keyValue: item.title,
                                  label: item.title,
                                  value: exchangeViewModel.selectedProviders.contains(item),
                                  onChanged: (val) {
                                    _switchProviderStatus(item, val, context);
                                  });
                            }).toList(),
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
                                for (final provider in centralizedProviders) {
                                  _switchProviderStatus(provider, true, context);
                                }
                              },
                              child: Text(
                                S.of(context).select_all,
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                for (final provider in centralizedProviders) {
                                  _switchProviderStatus(provider, false, context);
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
                                  exchangeViewModel.selectedProviders
                                      .firstWhereOrNull((e) => e.title == key) !=
                                  null,
                              updateCheckboxValue: (key, val) {},
                              sections: {
                                S.of(context).centralized: centralizedProviders.map((item) {
                                  return ListItemCheckbox(
                                      iconPath: item.description.image,
                                      keyValue: item.title,
                                      label: item.title,
                                      showArrow: item.title == "Trocador",
                                      value: exchangeViewModel.selectedProviders.contains(item),
                                      subtitle: item.title == "Trocador" ? S.of(context).manage_providers : null,
                                      onTap: item.title == "Trocador" ? (){
                                        _openTrocadorProvidersPage(context);
                                      } : null,
                                      onChanged: (val) {
                                        _switchProviderStatus(item, val, context);
                                      });
                                }).toList(),
                              }),
                          if (exchangeViewModel.forceDecentralizedExchanges)
                            Positioned.fill(
                                child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black12.withAlpha(128),
                                  borderRadius: BorderRadius.circular(16)),
                            ))
                        ],
                      ),
                      SizedBox(height:36)
                    ],
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  void _switchProviderStatus(ExchangeProvider provider, bool status, BuildContext context) {
    if (!provider.isAvailable) {
      showPopUp<void>(
          builder: (BuildContext popUpContext) => AlertWithOneAction(
              alertTitle: 'Error',
              alertContent: 'The exchange is blocked in your region.',
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop()),
          context: context);
      return;
    }
    if (status) {
      exchangeViewModel.addExchangeProvider(provider);
    } else {
      exchangeViewModel.removeExchangeProvider(provider);
    }
  }

  void _openTrocadorProvidersPage(BuildContext context) {
    final vm = getIt.get<TrocadorProvidersViewModel>();
    Navigator.of(context).push(CupertinoPageRoute(
        builder: (context) => Material(
                child: TrocadorProvidersSettings(
              trocadorProvidersViewModel: vm,
            ))));
  }
}
