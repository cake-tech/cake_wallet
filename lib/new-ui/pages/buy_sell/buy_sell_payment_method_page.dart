import "dart:async";

import "package:cake_wallet/buy/payment_method.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/view_model/buy/buy_sell_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class BuySellPaymentMethodPage extends StatelessWidget {
  const BuySellPaymentMethodPage({required this.buySellViewModel, super.key});

  final BuySellViewModel buySellViewModel;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceDim,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ModalTopBar(
                title: S.of(context).payment_method,
                leadingIcon: const Icon(Icons.arrow_back_ios_new),
                onLeadingPressed: Navigator.of(context).pop,
                leadingSemanticLabel: S.of(context).seed_alert_back,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Observer(
                    builder: (_) => NewListSections(
                      sections: {
                        "": buySellViewModel.paymentMethods
                            .map(
                              (item) => ListItemRegularRow(
                                keyValue: item.title,
                                label: item.title,
                                showArrow: false,
                                iconPath: Theme.of(context).brightness == Brightness.light
                                    ? item.lightIconPath
                                    : item.darkIconPath,
                                iconColor: item.paymentMethodType.isMonochromeIcon
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : null,
                                trailingWidget: buySellViewModel.selectedPaymentMethod == item
                                    ? Icon(
                                        Icons.check,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 16,
                                      )
                                    : null,
                                onTap: () {
                                  buySellViewModel.changeOption(item);
                                  unawaited(buySellViewModel.calculateBestRate());
                                  Navigator.of(context).pop();
                                },
                              ),
                            )
                            .toList(),
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
