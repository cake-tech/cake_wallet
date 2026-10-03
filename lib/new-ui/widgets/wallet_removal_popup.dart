import "package:cake_wallet/core/key_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/utils/clipboard_util.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/deprecated_wallet_seeds.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

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
                borderRadius: BorderRadius.circular(18)),
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
                          .map((item) => CakeImageWidget(
                                imageUrl: item,
                                width: 64,
                                height: 64,
                              ))
                          .toList(),
                    ),
                    Text(
                      textAlign: TextAlign.center,
                      S.of(context).support_will_soon_be_removed(typeNames.join(", ")),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    Text(
                        textAlign: TextAlign.center,
                        types.map(deprecationReasonForType).whereType<String>().join("\n\n")),
                    Text(
                      textAlign: TextAlign.center,
                      S.of(context).make_sure_you_migrated(typeNames.join("/")),
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: context.currentTheme.customColors.warningOutlineColor),
                    ),
                    NewListSections(sections: {
                      "": affectedWallets
                          .map((item) => ListItemRegularRow(
                              iconPath: walletTypeToCryptoCurrency(item.type).iconPath ?? "",
                              keyValue: item.name,
                              label: item.name,
                              showArrow: true,
                              onTap: () => _showBackedUpSeed(context, item)))
                          .toList()
                    }),
                    NewPrimaryButton(
                        onPressed: Navigator.of(context).pop,
                        text: S.of(context).close,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary)
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

  Future<void> _showBackedUpSeed(BuildContext context, WalletInfo wi) async {
    if(context.mounted) {
      final confirmed = await showPopUp<bool>(context: context, builder: (context)=>AlertWithTwoActions(
        alertTitle: "${wi.name} Seed",
        alertContent: S.of(context).show_seed_confirmation,
        leftButtonText: S.of(context).yes,
        rightButtonText: S.of(context).no,
        actionLeftButton: ()=>Navigator.of(context).pop(true),
        actionRightButton: ()=>Navigator.of(context).pop(false),

      ));

      if(!(confirmed ?? false)) {
        return;
      }
    }

    final seed = await _decryptSeed(wi);

    if (context.mounted) {
      final copied = await showPopUp<bool>(
          context: context,
          builder: (context) => AlertWithTwoActions(
                alertTitle: "${wi.name} Seed",
                alertContent:
                    "${seed?.seed ?? "backup failed, please open wallet to back up"}${seed?.passphrase == null ? "" : "\n\npassphrase: ${seed!.passphrase}"}",
                rightButtonText: S.of(context).close,
            leftButtonText: S.of(context).copy,
            actionLeftButton: ()=>Navigator.of(context).pop(true),
            actionRightButton: ()=>Navigator.of(context).pop(false),
              ));

      if((copied ?? false) && seed != null) {
        await ClipboardUtil.setSensitiveDataToClipboard(ClipboardData(text: seed.seed));
      }
    }
  }

  Future<DeprecatedWalletSeeds?> _decryptSeed(WalletInfo wi) async {
    try {
      return await DeprecatedWalletSeeds.get(
        wi.internalId,
        await getIt.get<KeyService>().getWalletPassword(walletName: wi.name),
      );
    } catch (e) {
      printV("${wi.name} seed decryption failed: $e");
      return null;
    }
  }
}
