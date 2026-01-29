import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_selector.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/provider_options_page.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/refund_address_modal.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SwapOptionsPage extends StatelessWidget {
  const SwapOptionsPage({super.key, required this.exchangeViewModel});

  final ExchangeViewModel exchangeViewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModalTopBar(
          title: S.of(context).configure,
          leadingIcon: Icon(Icons.arrow_back_ios_new),
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
                  Text(
                    "${exchangeViewModel.depositCurrency.title} → ${exchangeViewModel.receiveCurrency.title}",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary),
                  )
                ],
              ),
              Observer(
                builder: (_) => NewListSections(
                    showHeader: true,
                    getCheckboxValue: (key) => exchangeViewModel.isFixedRateMode,
                    updateCheckboxValue: (key, val) {},
                    sections: {
                      "": [
                        ListItemToggle(
                            keyValue: "fixed rate",
                            label: S.of(context).fixed_rate,
                            value: exchangeViewModel.isFixedRateMode,
                            onChanged: (val) {
                              if (val)
                                exchangeViewModel.enableFixedRateMode();
                              else
                                exchangeViewModel.isFixedRateMode = false;
                            }),
                        ListItemRegularRow(
                            keyValue: "refund",
                            label: S.of(context).set_refund_address,
                            onTap: () {
                              showModalBottomSheet(
                                isScrollControlled: true,
                                  context: context,
                                  builder: (context) {
                                    return RefundAddressModal(
                                        selectedCurrency: exchangeViewModel.depositCurrency);
                                  }).then((val) {
                                if (val != null && val is String) {
                                  exchangeViewModel.depositAddress = val;
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
                                          exchangeViewModel: exchangeViewModel))));
                            }),
                        ListItemRegularRow(
                            keyValue: "coin control",
                            label: "Coin Control",
                            onTap: () {
                              Navigator.of(context).pushNamed(Routes.unspentCoinsList);
                            }),
                        ListItemSelector(
                            keyValue: "curr",
                            label: S.of(context).change_fiat_currency,
                            options: [exchangeViewModel.fiat.name],
                            onTap: () {
                              exchangeViewModel.showFiatCurrencyPicker(context);
                            })
                      ]
                    }),
              )
            ],
          ),
        )
      ],
    );
  }
}
