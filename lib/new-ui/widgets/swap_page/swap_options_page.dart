import "package:cake_wallet/di.dart";
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_selector.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/pages/coin_control_page.dart';
import "package:cake_wallet/new-ui/viewmodels/swap/swap_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart";
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/provider_options_page.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/refund_address_modal.dart';
import "package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart";
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import "package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart";
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:flutter_bloc/flutter_bloc.dart";
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class SwapOptionsPage extends StatelessWidget {
  const SwapOptionsPage({required this.bloc, super.key});

  final SwapBloc bloc;


  @override
  Widget build(BuildContext context) => BlocBuilder<SwapBloc, SwapState>(
    bloc: bloc,
  builder: (context, state) => Column(
      children: [
        ModalTopBar(
          title: S.of(context).configure,
          leadingIcon: const Icon(Icons.arrow_back_ios_new),
          onLeadingPressed: Navigator.of(context).pop,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            spacing: 24,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).current_swap,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  if(state is SwapStateWithInputs)
                  Text(
                    "${state.depositAmount.currency.title} → ${state.payoutAmount.currency.title}",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary),
                  )
                ],
              ),
              if(state is SwapStateWithInputs)
              Observer(
                builder: (_) => NewListSections(
                    showHeader: true,
                    getCheckboxValue: (key) => state.isFixedRate,
                    updateCheckboxValue: (key, val) {},
                    sections: {
                      "": [
                        ListItemToggle(
                            keyValue: "fixed rate",
                            label: S.of(context).fixed_rate,
                            value: state.isFixedRate,
                            onChanged: (val) {
                              bloc.add(FixedRateToggled());
                            }),
                        ListItemRegularRow(
                            keyValue: "refund",
                            label: S.of(context).set_refund_address,
                            onTap: () {
                              showModalBottomSheet(
                                  isScrollControlled: true,
                                  context: context,
                                  builder: (context) => RefundAddressModal(
                                        selectedCurrency: state.depositAmount.currency)).then((val) {
                                if (val != null && val is String) {
                                  bloc.add(SourceChanged(ExternalSwapSource(val)));
                                }
                              });
                            })
                      ],
                      S.of(context).general: [
                        ListItemRegularRow(
                            keyValue: "providers",
                            label: S.of(context).swap_providers,
                            onTap: () {
                              Navigator.of(context).push(CupertinoPageRoute(
                                  builder: (context) => Material(
                                      child: ProviderOptionsPage(
                                          bloc: bloc))));
                            }),
                        ListItemRegularRow(
                            keyValue: "coin control",
                            label: "Coin Control",
                            onTap: () {
                              showCupertinoModalBottomSheet(
                                  enableDrag: false,
                                  useRootNavigator: true,
                                  isDismissible: false,
                                  context: context,
                                  builder: (context) => NewCoinControlPage(
                                      unspentCoinsListViewModel:
                                          getIt.get<UnspentCoinsListViewModel>(),
                                      canEdit: true,
                                    ));
                            }),
                        ListItemSelector(
                            keyValue: "curr",
                            label: S.of(context).change_fiat_currency,
                            options: [bloc.fiat.name],
                            onTap: () {
                              FiatCurrencyPickerSheet.show(
                                context: context,
                                selected: bloc.fiat,
                                onSelected: (curr) {
                                  bloc.add(FiatCurrencyChanged(curr));
                                },
                              );

                            })
                      ]
                    }),
              )
            ],
          ),
        )
      ],
    ),
);
}
