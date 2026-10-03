import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";

class WalletRemovalPopup extends StatelessWidget {
  const WalletRemovalPopup({required this.affectedWallets, super.key});

  final List<WalletInfo> affectedWallets;

  @override
  Widget build(BuildContext context) {
    final types = affectedWallets.map((item) => item.type).toSet().toList();
    final iconPaths = types.map((item) => walletTypeToCryptoCurrency(item).iconPath ?? "").toList();
    final typeNames = types.map(walletTypeToDisplayName).toList();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 18,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8,
                      children: iconPaths
                          .map(
                            (item) => CakeImageWidget(
                              imageUrl: item,
                              width: 64,
                              height: 64,
                            ),
                          )
                          .toList(),
                    ),
                    Text(
                      textAlign: TextAlign.center,
                      S.of(context).support_will_soon_be_removed(typeNames.join(", ")),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      textAlign: TextAlign.center,
                      types.map(deprecationReasonForType).whereType<String>().join("\n\n"),
                    ),
                    Text(
                      textAlign: TextAlign.center,
                      S.of(context).make_sure_you_migrated(typeNames.join("/")),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: context.currentTheme.customColors.warningOutlineColor,
                      ),
                    ),
                    NewListSections(
                      sections: {
                        "": affectedWallets
                            .map(
                              (item) => ListItemRegularRow(
                                iconPath: walletTypeToCryptoCurrency(item.type).iconPath ?? "",
                                keyValue: item.name,
                                label: item.name,
                                showArrow: true,
                              ),
                            )
                            .toList(),
                      },
                    ),
                    NewPrimaryButton(
                      onPressed: Navigator.of(context).pop,
                      text: S.of(context).close,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? deprecationReasonForType(WalletType type) =>
      switch (type) { WalletType.zano => S.current.zano_removal_reason, _ => null };
}
