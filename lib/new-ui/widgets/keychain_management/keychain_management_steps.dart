import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/keychain_info_step.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:flutter/material.dart";

class KeychainNotRestoredIcon extends StatelessWidget {
  const KeychainNotRestoredIcon({super.key});

  @override
  Widget build(BuildContext context) => CakeImageWidget(
        imageUrl: "assets/new-ui/not_restored.svg",
        width: 48,
        height: 48,
        colorFilter: ColorFilter.mode(
          context.currentTheme.customColors.warningOutlineColor,
          BlendMode.srcIn,
        ),
      );
}

class KeychainNotRestoredStep extends StatelessWidget {
  const KeychainNotRestoredStep({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => KeychainInfoStep(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        icons: const [KeychainNotRestoredIcon()],
        title: title,
        titleColor: context.currentTheme.customColors.warningOutlineColor,
        subtitle: subtitle,
      );
}

class KeychainManualBackupStep extends StatelessWidget {
  const KeychainManualBackupStep({
    required this.title,
    this.titleColor,
    this.iconSize = 48,
    this.faded = true,
    this.centered = false,
    super.key,
  });

  final String title;
  final Color? titleColor;
  final double iconSize;
  final bool faded;
  final bool centered;

  @override
  Widget build(BuildContext context) => KeychainInfoStep(
        centered: centered,
        icons: [
          Opacity(
            opacity: faded ? 0.25 : 1,
            child: CakeImageWidget(
              imageUrl: "assets/new-ui/cloud_keys.svg",
              width: iconSize,
              height: iconSize,
            ),
          ),
          SizedBox.square(
            dimension: iconSize,
            child: Center(
              child: CakeImageWidget(
                imageUrl: "assets/new-ui/manual_backup.svg",
                width: iconSize * 0.8,
                height: iconSize * 0.8,
              ),
            ),
          ),
        ],
        title: title,
        titleColor: titleColor,
      );
}

class KeychainRestoreFromWalletsStep extends StatelessWidget {
  const KeychainRestoreFromWalletsStep({super.key});

  @override
  Widget build(BuildContext context) => KeychainInfoStep(
        icons: [
          CakeImageWidget(
            imageUrl: "assets/new-ui/wallet_filled.svg",
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),
        ],
        title: S.of(context).keychain_restore_from_wallets_tab,
      );
}

class KeychainWalletNotRestoredContent extends StatelessWidget {
  const KeychainWalletNotRestoredContent({this.onViewRecoveryPhrase, super.key});

  final VoidCallback? onViewRecoveryPhrase;

  @override
  Widget build(BuildContext context) => Column(
        spacing: 24,
        children: [
          const KeychainNotRestoredIcon(),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "${S.of(context).wallet_not_restored_on_device}\n\n",
                  style: TextStyle(color: context.currentTheme.customColors.warningOutlineColor),
                ),
                TextSpan(text: "${S.of(context).import_wallet_now_question}\n\n"),
                TextSpan(
                  text: S.of(context).view_recovery_phrase_without_restoring,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
          ),
          NewListSections(
            sections: {
              "": [
                ListItemRegularRow(
                  keyValue: "view recovery phrase",
                  label: S.of(context).view_wallet_recovery_phrase,
                  iconPath: "assets/new-ui/manual_backup.svg",
                  onTap: onViewRecoveryPhrase,
                ),
              ],
            },
          ),
        ],
      );
}

class KeychainUnrestoredWalletsInfo extends StatelessWidget {
  const KeychainUnrestoredWalletsInfo({super.key});

  @override
  Widget build(BuildContext context) => Column(
        spacing: 12,
        children: [
          KeychainNotRestoredStep(
            title: S.of(context).some_wallets_currently_unrestored,
            subtitle: S.of(context).keychain_unrestored_wallets_desc,
          ),
          const KeychainRestoreFromWalletsStep(),
          KeychainManualBackupStep(title: S.of(context).keychain_manual_backup_lose_access),
        ],
      );
}

class KeychainUnrestoredWalletsSheet extends StatelessWidget {
  const KeychainUnrestoredWalletsSheet({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTopBar(
                title: S.of(context).restore_cloud_wallets,
                trailingIcon: const Icon(Icons.close),
                trailingSemanticLabel: S.of(context).close,
                onTrailingPressed: Navigator.of(context).pop,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 32,
                  children: [
                    const KeychainUnrestoredWalletsInfo(),
                    NewPrimaryButton(
                      onPressed: Navigator.of(context).pop,
                      text: S.of(context).ok,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
