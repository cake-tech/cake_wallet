import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/seed/open_wallet_after_seed_flow.dart";
import "package:cake_wallet/new-ui/pages/seed/skip_seed_verification_page.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_checkbox_row.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_hero_image.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_page_header.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_page_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/stacked_buttons.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class PreSeedPage extends StatefulWidget {
  const PreSeedPage(this.wallet, {super.key});

  final WalletBase wallet;

  @override
  State<PreSeedPage> createState() => _PreSeedPageState();
}

class _PreSeedPageState extends State<PreSeedPage> {
  bool _understandsOnlyWayToRecover = false;
  bool _willWriteItDown = false;
  bool _willNeverShareIt = false;

  bool get _hasCheckedAll => _understandsOnlyWayToRecover && _willWriteItDown && _willNeverShareIt;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: SeedPageScaffold(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              SeedPageHeader(
                image: const SeedHeroImage(),
                title: S.of(context).recovery_phrase_intro_title,
                description: Text(
                  S.of(context).recovery_phrase_intro_description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: -0.07,
                      ),
                ),
              ),
              Column(
                spacing: 12,
                children: [
                  SeedCheckboxRow(
                    key: const ValueKey("pre_seed_page_only_way_checkbox_key"),
                    iconPath: "assets/new-ui/key.svg",
                    text: S.of(context).recovery_phrase_check_only_way,
                    isChecked: _understandsOnlyWayToRecover,
                    onChanged: (value) => setState(() => _understandsOnlyWayToRecover = value),
                  ),
                  SeedCheckboxRow(
                    key: const ValueKey("pre_seed_page_write_down_checkbox_key"),
                    iconPath: "assets/new-ui/set-amount.svg",
                    text: S.of(context).recovery_phrase_check_write_down,
                    isChecked: _willWriteItDown,
                    onChanged: (value) => setState(() => _willWriteItDown = value),
                  ),
                  SeedCheckboxRow(
                    key: const ValueKey("pre_seed_page_never_share_checkbox_key"),
                    iconPath: "assets/new-ui/visibility.svg",
                    text: S.of(context).recovery_phrase_check_never_share,
                    isChecked: _willNeverShareIt,
                    onChanged: (value) => setState(() => _willNeverShareIt = value),
                  ),
                ],
              ),
              if (!_hasCheckedAll)
                Text(
                  S.of(context).recovery_phrase_check_all_to_proceed,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.customColors.warningOutlineColor,
                        letterSpacing: -0.07,
                      ),
                ),
            ],
          ),
          footer: _hasCheckedAll
              ? StackedButtons(
                  primaryKey: const ValueKey("pre_seed_page_button_key"),
                  primaryText: S.of(context).show_recovery_phrase,
                  onPrimary: () => Navigator.of(context).pushNamed(Routes.seed, arguments: true),
                  secondaryKey: const ValueKey("pre_seed_page_skip_button_key"),
                  secondaryText: S.of(context).skip_this_step,
                  onSecondary: _confirmSkip,
                  secondaryAsLink: true,
                )
              : null,
          alignTop: true,
        ),
      );

  void _confirmSkip() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => SkipSeedVerificationPage(onConfirm: _skipVerification),
      ),
    );
  }

  Future<void> _skipVerification() async {
    await widget.wallet.walletInfo.updateShowSeedBackupReminder(true);

    if (!mounted) {
      return;
    }

    openWalletAfterSeedFlow(context, widget.wallet.type);
  }
}
