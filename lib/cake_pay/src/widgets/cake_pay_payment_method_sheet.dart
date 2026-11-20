import "package:cake_wallet/cake_pay/src/models/cake_pay_payment_method.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";

class CakePayPaymentMethodSheet extends StatelessWidget {
  const CakePayPaymentMethodSheet({required this.methods, super.key});

  final List<CakePayPaymentMethod> methods;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTopBar(
                title: S.of(context).payment_method,
                leadingIcon: const Icon(Icons.close),
                leadingSemanticLabel: S.of(context).close,
                onLeadingPressed: Navigator.of(context).pop,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: NewListSections(
                    sections: {
                      "": [
                        for (final method in methods)
                          ListItemRegularRow(
                            keyValue: method.name,
                            label: method.label,
                            iconPath: switch (method) {
                              CakePayPaymentMethod.USDC => CryptoCurrency.usdc.iconPath,
                              CakePayPaymentMethod.USDT => CryptoCurrency.usdt.iconPath,
                              _ => null,
                            },
                            showArrow: false,
                            onTap: () => Navigator.of(context).pop(method),
                          ),
                      ],
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
