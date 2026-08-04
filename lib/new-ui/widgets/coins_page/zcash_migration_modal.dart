import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class ZcashMigrationModal extends StatelessWidget {
  const ZcashMigrationModal({required this.hasContinue, required this.balance, super.key});

  final String balance;
  final bool hasContinue;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).zcash_network_upgrade,
              trailingIcon: const Icon(Icons.close),
              onTrailingPressed: Navigator.of(context).pop,
              trailingSemanticLabel: S.of(context).close,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        spacing: 40,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 146,
                            height: 79,
                            child: Stack(
                              children: [
                                const Positioned(
                                  left: 67,
                                      top: 0,
                                      bottom: 0,
                                      child: CakeImageWidget(
                                    imageUrl: "assets/new-ui/ironwood_migration.svg",
                                    width: 75,
                                    height: 75,
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  child: Container(
                                    width: 79,
                                    height: 79,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(99999999),
                                        border: Border.all(
                                            color: Theme.of(context).colorScheme.surface,
                                            width: 4,),),
                                    child: const CakeImageWidget(
                                      imageUrl: "assets/new-ui/crypto_full_icons/zcash.svg",
                                      height: 75,
                                      width: 75,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Theme.of(context).colorScheme.surfaceContainer,),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      balance,
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,),
                                    ),
                                    Text(S.of(context).is_currently_being_migrated),
                                  ],
                                ),
                              ),),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                    text: "${S.of(context).zcash_network_upgrade_desc_1}\n\n",
                                    style: Theme.of(context).textTheme.bodyMedium,),
                                TextSpan(
                                    text: "${S.of(context).zcash_network_upgrade_desc_2}\n\n",
                                    style: Theme.of(context).textTheme.bodyMedium,),
                                TextSpan(
                                  text: "${S.of(context).zcash_network_upgrade_desc_3}\n\n",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFFF9C03C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                spacing: 12,
                children: [
                  NewPrimaryButton(
                      onPressed: _launchDocs,
                      text: S.of(context).learn_more,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      textColor: Theme.of(context).colorScheme.primary,),
                  if (hasContinue)
                    NewPrimaryButton(
                        onPressed: Navigator.of(context).pop,
                        text: S.of(context).continue_text,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _launchDocs() {
    try {
      launchUrl(Uri.parse("https://docs.cakewallet.com/cryptos/zcash/ironwood-migration"));
    } catch (_) {}
  }
}
