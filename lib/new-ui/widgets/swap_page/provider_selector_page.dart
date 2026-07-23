import "package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/rates/rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/swap_bloc.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class ProviderSelectorPage extends StatelessWidget {
  const ProviderSelectorPage({required this.bloc, super.key});

  final SwapBloc bloc;

  @override
  Widget build(BuildContext context) => BlocBuilder<RateCubit, RateState>(
        bloc: bloc.rateCubit,
        builder: (context, rateState) => BlocBuilder<SwapBloc, SwapState>(
          bloc: bloc,
          builder: (context, state) {
            if (state case final SwapInputState s) {
              final decentralizedProviders =
                  s.availableProviders.where((item) => !item.isCentralized);
              final centralizedProviders = s.availableProviders.where((item) => item.isCentralized);
              final ExchangeProviderDescription? bestRateProvider;
              if (rateState case final RatesLoaded rs) {
                bestRateProvider = rs.rates.max.provider;
              } else {
                bestRateProvider = null;
              }

              return Column(
                children: [
                  ModalTopBar(
                    title: S.of(context).change_provider,
                    leadingIcon: const Icon(Icons.arrow_back_ios_new),
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
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: NewListSections(
                              showHeader: true,
                              getCheckboxValue: (_) => s.forcedProvider == null,
                              updateCheckboxValue: (key, value) {},
                              sections: {
                                if (bestRateProvider != null)
                                  S.of(context).best_rate: [
                                    ListItemCheckbox(
                                      iconPath: bestRateProvider.image,
                                      keyValue: "bestrate",
                                      label: bestRateProvider.title,
                                      subtitle: bestRateProvider.isCentralized
                                          ? S.of(context).centralized
                                          : S.of(context).decentralized,
                                      value: s.forcedProvider == null,
                                      onChanged: (val) {
                                        bloc.add(const ForcedProviderSelected(null));
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                S.of(context).decentralized: decentralizedProviders
                                    .map(
                                      (item) => ListItemRegularRow(
                                        iconPath: item.image,
                                        keyValue: item.title,
                                        label: item.title,
                                        onTap: () {
                                          bloc.add(ForcedProviderSelected(item));
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    )
                                    .toList(),
                                S.of(context).centralized: centralizedProviders
                                    .map(
                                      (item) => ListItemRegularRow(
                                        iconPath: item.image,
                                        keyValue: item.title,
                                        label: item.title,
                                        onTap: () {
                                          bloc.add(ForcedProviderSelected(item));
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    )
                                    .toList(),
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
}
